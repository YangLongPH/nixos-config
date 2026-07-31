import asyncio
import os
import sys
import tempfile
from contextlib import asynccontextmanager
from typing import Optional

import torch
import uvicorn
from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.responses import Response
from huggingface_hub import snapshot_download
from PIL import Image

CACHE_DIR = os.environ.get("HUGGINGFACE_HUB_CACHE", "/root/.cache/huggingface")
WEIGHTS_DIR = "/app/weights"

pipe = None
nirne = None
inference_lock = asyncio.Lock()


@asynccontextmanager
async def lifespan(app: FastAPI):
    global pipe, nirne
    sys.path.insert(0, "/app")
    os.makedirs(WEIGHTS_DIR, exist_ok=True)

    # Download Hi3DGen TRELLIS-based model
    snapshot_download(
        repo_id="Stable-X/trellis-normal-v0-1",
        local_dir=os.path.join(WEIGHTS_DIR, "trellis-normal-v0-1"),
    )

    from hi3dgen.pipelines import Hi3DGenPipeline
    pipe = Hi3DGenPipeline.from_pretrained(
        os.path.join(WEIGHTS_DIR, "trellis-normal-v0-1")
    )
    pipe.cuda()

    # NiRNE normal estimator (submodule at /app/NiRNE)
    nirne = torch.hub.load(
        "/app/NiRNE", "NiRNE",
        trust_repo=True,
        local_cache_dir=WEIGHTS_DIR,
        source="local",
    )
    nirne.cuda()

    yield


app = FastAPI(title="Hi3DGen API", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": pipe is not None and nirne is not None}


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    ss_steps: int = Query(default=50, ge=1, le=100, description="Sparse structure steps"),
    ss_guidance: float = Query(default=3.0, ge=0.0, description="Sparse structure guidance"),
    slat_steps: int = Query(default=6, ge=1, le=50, description="Structured latent steps"),
    slat_guidance: float = Query(default=3.0, ge=0.0, description="Structured latent guidance"),
    seed: int = Query(default=42),
):
    if pipe is None or nirne is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    image_data = await file.read()

    async with inference_lock:
        torch.cuda.empty_cache()
        with tempfile.TemporaryDirectory() as tmp_dir:
            img_path = os.path.join(tmp_dir, "input.png")
            with open(img_path, "wb") as f:
                f.write(image_data)

            image = Image.open(img_path).convert("RGB")

            # Stage 1: preprocess + normal estimation
            image = pipe.preprocess_image(image, resolution=1024)
            normal_image = nirne(
                image,
                resolution=768,
                match_input_resolution=True,
                data_type="object",
            )

            # Stage 2: 3D generation from normal map
            with torch.no_grad():
                outputs = pipe.run(
                    normal_image,
                    seed=seed,
                    formats=["mesh"],
                    preprocess_image=False,
                    sparse_structure_sampler_params={
                        "steps": ss_steps,
                        "cfg_strength": ss_guidance,
                    },
                    slat_sampler_params={
                        "steps": slat_steps,
                        "cfg_strength": slat_guidance,
                    },
                )

            mesh = outputs["mesh"][0]
            trimesh_mesh = mesh.to_trimesh(transform_pose=True)

            output_path = os.path.join(tmp_dir, "output.glb")
            trimesh_mesh.export(output_path)
            with open(output_path, "rb") as f:
                glb_bytes = f.read()

    return Response(
        content=glb_bytes,
        media_type="model/gltf-binary",
        headers={"Content-Disposition": 'attachment; filename="output.glb"'},
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8096)
