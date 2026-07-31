import asyncio
import os
import tempfile
from contextlib import asynccontextmanager

import torch
import uvicorn
from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.responses import Response
from huggingface_hub import snapshot_download
from PIL import Image

CACHE_DIR = os.environ.get("HUGGINGFACE_HUB_CACHE", "/root/.cache/huggingface")
MODEL_REPO = "JeffreyXiang/TRELLIS-image-large"

pipe = None
inference_lock = asyncio.Lock()


@asynccontextmanager
async def lifespan(app: FastAPI):
    global pipe
    import sys
    sys.path.insert(0, "/app")
    os.environ["ATTN_BACKEND"] = "flash-attn"
    os.environ["SPCONV_ALGO"] = "native"

    from trellis.pipelines import TrellisImageTo3DPipeline

    model_dir = snapshot_download(repo_id=MODEL_REPO, local_dir=os.path.join(CACHE_DIR, "TRELLIS"))
    pipe = TrellisImageTo3DPipeline.from_pretrained(model_dir)
    pipe.cuda()
    yield


app = FastAPI(title="TRELLIS API", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": pipe is not None}


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    num_inference_steps: int = Query(default=50, ge=1, le=200),
    guidance_scale: float = Query(default=7.5, ge=0.0),
    seed: int = Query(default=42),
    texture_size: int = Query(default=1024, ge=512, le=2048),
    simplify: float = Query(default=0.95, ge=0.0, le=1.0),
):
    if pipe is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    image_data = await file.read()

    async with inference_lock:
        torch.cuda.empty_cache()
        with tempfile.TemporaryDirectory() as tmp_dir:
            img_path = os.path.join(tmp_dir, "input.png")
            with open(img_path, "wb") as f:
                f.write(image_data)

            image = Image.open(img_path).convert("RGBA")

            with torch.no_grad():
                outputs = pipe.run(
                    image,
                    seed=seed,
                    num_inference_steps=num_inference_steps,
                    guidance_scale=guidance_scale,
                )

            from trellis.utils import postprocessing_utils
            glb = postprocessing_utils.to_glb(
                outputs["gaussian"][0],
                outputs["mesh"][0],
                simplify=simplify,
                texture_size=texture_size,
                verbose=False,
            )

            output_path = os.path.join(tmp_dir, "output.glb")
            glb.export(output_path)
            with open(output_path, "rb") as f:
                glb_bytes = f.read()

    return Response(
        content=glb_bytes,
        media_type="model/gltf-binary",
        headers={"Content-Disposition": 'attachment; filename="output.glb"'},
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8097)
