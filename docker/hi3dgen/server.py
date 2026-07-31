import asyncio
import os
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
MODEL_REPO = "3DTopia/Hi3DGen"

pipe = None
inference_lock = asyncio.Lock()


@asynccontextmanager
async def lifespan(app: FastAPI):
    global pipe
    import sys
    sys.path.insert(0, "/app")

    model_dir = snapshot_download(repo_id=MODEL_REPO, local_dir=os.path.join(CACHE_DIR, "Hi3DGen"))

    from pipeline import Hi3DGenPipeline
    pipe = Hi3DGenPipeline.from_pretrained(model_dir).to("cuda")
    yield


app = FastAPI(title="Hi3DGen API", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": pipe is not None}


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    num_inference_steps: int = Query(default=50, ge=1, le=200),
    guidance_scale: float = Query(default=7.5, ge=0.0),
    seed: int = Query(default=42),
):
    if pipe is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    image_data = await file.read()

    async with inference_lock:
        with tempfile.TemporaryDirectory() as tmp_dir:
            img_path = os.path.join(tmp_dir, "input.png")
            with open(img_path, "wb") as f:
                f.write(image_data)

            image = Image.open(img_path).convert("RGB")

            generator = torch.Generator(device="cuda").manual_seed(seed)
            with torch.no_grad():
                outputs = pipe(
                    image=image,
                    num_inference_steps=num_inference_steps,
                    guidance_scale=guidance_scale,
                    generator=generator,
                )

            mesh = outputs.meshes[0]
            output_path = os.path.join(tmp_dir, "output.glb")
            mesh.export(output_path)
            with open(output_path, "rb") as f:
                glb_bytes = f.read()

    return Response(
        content=glb_bytes,
        media_type="model/gltf-binary",
        headers={"Content-Disposition": 'attachment; filename="output.glb"'},
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8096)
