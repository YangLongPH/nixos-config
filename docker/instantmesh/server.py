import asyncio
import os
import sys
import tempfile

import torch
import uvicorn
from fastapi import FastAPI, File, Query, UploadFile
from fastapi.responses import Response
from PIL import Image

CACHE_DIR = os.environ.get("HUGGINGFACE_HUB_CACHE", "/root/.cache/huggingface")
MODEL_REPO = "TencentARC/InstantMesh"

inference_lock = asyncio.Lock()

app = FastAPI(title="InstantMesh API", version="1.0.0")


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": False}


def preprocess_image(image: Image.Image) -> Image.Image:
    from rembg import remove
    image = image.convert("RGBA")
    if image.mode == "RGB":
        image = remove(image)
    bg = Image.new("RGBA", image.size, (127, 127, 127, 255))
    bg.paste(image, mask=image.split()[3])
    return bg.convert("RGB").resize((320, 320))


def _get_model_dir():
    local_dir = os.path.join(CACHE_DIR, "InstantMesh")
    if os.path.exists(os.path.join(local_dir, "instant_mesh_large.ckpt")):
        return local_dir
    sys.path.insert(0, "/app/src")
    from huggingface_hub import snapshot_download
    return snapshot_download(repo_id=MODEL_REPO, local_dir=local_dir)


def _run_multiview(image: Image.Image, num_inference_steps: int, seed: int):
    from diffusers import DiffusionPipeline, EulerAncestralDiscreteScheduler
    pipe = DiffusionPipeline.from_pretrained(
        "sudo-ai/zero123plus-v1.2",
        custom_pipeline="zero123plus",
        torch_dtype=torch.float16,
        trust_remote_code=True,
    ).to("cuda")
    pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(
        pipe.scheduler.config, timestep_spacing="trailing"
    )
    try:
        generator = torch.Generator(device="cuda").manual_seed(seed)
        mv_images = pipe(image, num_inference_steps=num_inference_steps, generator=generator).images[0]
    finally:
        del pipe
        torch.cuda.empty_cache()

    views = []
    w, h = mv_images.size
    view_w, view_h = w // 3, h // 2
    for row in range(2):
        for col in range(3):
            box = (col * view_w, row * view_h, (col + 1) * view_w, (row + 1) * view_h)
            views.append(mv_images.crop(box))
    return views


def _run_reconstruction(views, model_dir: str) -> bytes:
    from src.utils.train_util import instantiate_from_config
    from omegaconf import OmegaConf
    import torchvision.transforms.functional as TF
    from src.utils.camera_util import get_zero123plus_input_cameras

    config = OmegaConf.load("/app/configs/instant-mesh-large.yaml")
    reconstruction_model = instantiate_from_config(config.model_config)
    ckpt_path = os.path.join(model_dir, "instant_mesh_large.ckpt")
    state_dict = torch.load(ckpt_path, map_location="cpu")["state_dict"]
    state_dict = {k[len("lrm_generator."):]: v for k, v in state_dict.items()
                  if k.startswith("lrm_generator.") and "source_camera" not in k}
    reconstruction_model.load_state_dict(state_dict, strict=True)
    reconstruction_model = reconstruction_model.to("cuda").eval()
    reconstruction_model.grid_res = 64
    reconstruction_model.init_flexicubes_geometry("cuda", fovy=30.0)

    try:
        mv_tensor = torch.stack([TF.to_tensor(v) for v in views]).unsqueeze(0).to("cuda")
        input_cameras = get_zero123plus_input_cameras(batch_size=1, radius=4.0).to("cuda")
        with torch.no_grad():
            planes = reconstruction_model.forward_planes(mv_tensor, input_cameras)
            vertices, faces, _ = reconstruction_model.extract_mesh(planes)

        import trimesh
        mesh = trimesh.Trimesh(vertices=vertices, faces=faces)
        with tempfile.NamedTemporaryFile(suffix=".obj", delete=False) as f:
            tmp_path = f.name
        mesh.export(tmp_path)
        with open(tmp_path, "rb") as f:
            return f.read()
    finally:
        del reconstruction_model
        torch.cuda.empty_cache()


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    num_inference_steps: int = Query(default=75, ge=1, le=200),
    seed: int = Query(default=42),
):
    image_data = await file.read()

    async with inference_lock:
        loop = asyncio.get_event_loop()

        model_dir = await loop.run_in_executor(None, _get_model_dir)

        image = Image.open(__import__("io").BytesIO(image_data)).convert("RGB")
        image = preprocess_image(image)

        views = await loop.run_in_executor(None, _run_multiview, image, num_inference_steps, seed)
        obj_bytes = await loop.run_in_executor(None, _run_reconstruction, views, model_dir)

    return Response(
        content=obj_bytes,
        media_type="text/plain",
        headers={"Content-Disposition": 'attachment; filename="output.obj"'},
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8095)
