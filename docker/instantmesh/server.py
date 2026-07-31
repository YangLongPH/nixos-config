import asyncio
import os
import tempfile
from contextlib import asynccontextmanager
from typing import Optional

import numpy as np
import torch
import trimesh
import uvicorn
from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.responses import Response
from huggingface_hub import snapshot_download
from PIL import Image

CACHE_DIR = os.environ.get("HUGGINGFACE_HUB_CACHE", "/root/.cache/huggingface")
MODEL_REPO = "TencentARC/InstantMesh"

multiview_pipe = None
reconstruction_model = None
inference_lock = asyncio.Lock()


@asynccontextmanager
async def lifespan(app: FastAPI):
    global multiview_pipe, reconstruction_model
    import sys
    sys.path.insert(0, "/app/src")

    from diffusers import DiffusionPipeline, EulerAncestralDiscreteScheduler

    model_dir = snapshot_download(repo_id=MODEL_REPO, local_dir=os.path.join(CACHE_DIR, "InstantMesh"))

    multiview_pipe = DiffusionPipeline.from_pretrained(
        "sudo-ai/zero123plus-v1.2",
        custom_pipeline="zero123plus",
        torch_dtype=torch.float16,
    ).to("cuda")
    multiview_pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(
        multiview_pipe.scheduler.config, timestep_spacing="trailing"
    )

    from src.utils.train_util import instantiate_from_config
    from omegaconf import OmegaConf

    config_path = os.path.join("/app", "configs", "instant-mesh-large.yaml")
    config = OmegaConf.load(config_path)
    reconstruction_model = instantiate_from_config(config.model_config)
    ckpt_path = os.path.join(model_dir, "instant_mesh_large.ckpt")
    state_dict = torch.load(ckpt_path, map_location="cpu")["state_dict"]
    reconstruction_model.load_state_dict(state_dict, strict=True)
    reconstruction_model = reconstruction_model.to("cuda").eval()

    yield


def preprocess_image(image: Image.Image) -> Image.Image:
    from rembg import remove
    image = image.convert("RGBA")
    if image.mode == "RGB":
        image = remove(image)
    bg = Image.new("RGBA", image.size, (127, 127, 127, 255))
    bg.paste(image, mask=image.split()[3])
    return bg.convert("RGB").resize((320, 320))


app = FastAPI(title="InstantMesh API", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": reconstruction_model is not None}


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    num_inference_steps: int = Query(default=75, ge=1, le=200),
    seed: int = Query(default=42),
):
    if reconstruction_model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    image_data = await file.read()

    async with inference_lock:
        with tempfile.TemporaryDirectory() as tmp_dir:
            img_path = os.path.join(tmp_dir, "input.png")
            with open(img_path, "wb") as f:
                f.write(image_data)

            image = Image.open(img_path).convert("RGB")
            image = preprocess_image(image)

            generator = torch.Generator(device="cuda").manual_seed(seed)
            mv_images = multiview_pipe(
                image,
                num_inference_steps=num_inference_steps,
                generator=generator,
            ).images[0]

            # Tile into 6 views (2x3 grid from zero123plus output)
            views = []
            w, h = mv_images.size
            view_w, view_h = w // 3, h // 2
            for row in range(2):
                for col in range(3):
                    box = (col * view_w, row * view_h, (col + 1) * view_w, (row + 1) * view_h)
                    views.append(mv_images.crop(box))

            import torchvision.transforms.functional as TF
            mv_tensor = torch.stack([TF.to_tensor(v) for v in views]).unsqueeze(0).to("cuda")

            with torch.no_grad():
                planes = reconstruction_model.forward_planes(mv_tensor)
                mesh = reconstruction_model.extract_mesh(planes)[0]

            output_path = os.path.join(tmp_dir, "output.obj")
            mesh.export(output_path)
            with open(output_path, "rb") as f:
                obj_bytes = f.read()

    return Response(
        content=obj_bytes,
        media_type="text/plain",
        headers={"Content-Disposition": 'attachment; filename="output.obj"'},
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8095)
