import subprocess
for _pkg, _pip in [("skimage", "scikit-image"), ("cv2", "opencv-python-headless"), ("timm.layers", "timm>=0.9")]:
    try:
        __import__(_pkg)
    except ImportError:
        subprocess.run(["pip", "install", _pip, "-q"], check=False)

try:
    import flash_attn._flash_attn_cuda  # noqa
except (ImportError, OSError):
    subprocess.run(["pip", "uninstall", "flash-attn", "-y", "-q"], check=False)

import importlib.metadata as _meta
tv = _meta.version("transformers")
if tv < "4.48" or tv >= "4.49":
    subprocess.run(["pip", "install", "transformers==4.48.0", "-q"], check=False)

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
WEIGHTS_DIR = os.path.join(CACHE_DIR, "hi3dgen-weights")

inference_lock = asyncio.Lock()
app = FastAPI(title="Hi3DGen API", version="1.0.0")


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": False}


def _ensure_weights():
    sys.path.insert(0, "/app")
    os.makedirs(WEIGHTS_DIR, exist_ok=True)
    from huggingface_hub import snapshot_download

    trellis_local = os.path.join(WEIGHTS_DIR, "trellis-normal-v0-1")
    try:
        snapshot_download(repo_id="Stable-X/trellis-normal-v0-1", local_dir=trellis_local, local_files_only=True)
    except Exception:
        snapshot_download(repo_id="Stable-X/trellis-normal-v0-1", local_dir=trellis_local)

    nirne_local = os.path.join(WEIGHTS_DIR, "NiRNE")
    try:
        snapshot_download(repo_id="Stable-X/yoso-normal-v1-8-1", local_dir=nirne_local, local_files_only=True)
    except Exception:
        snapshot_download(repo_id="Stable-X/yoso-normal-v1-8-1", local_dir=nirne_local)


def _run_inference(image_data, ss_steps, ss_guidance, slat_steps, slat_guidance, seed):
    sys.path.insert(0, "/app")
    _ensure_weights()

    trellis_local = os.path.join(WEIGHTS_DIR, "trellis-normal-v0-1")

    with tempfile.TemporaryDirectory() as tmp_dir:
        img_path = os.path.join(tmp_dir, "input.png")
        with open(img_path, "wb") as f:
            f.write(image_data)
        image = Image.open(img_path).convert("RGB")

        # --- Phase 1: NiRNE normal estimation ---
        torch.cuda.empty_cache()
        nirne = torch.hub.load(
            "/app/NiRNE", "NiRNE",
            trust_repo=True,
            local_cache_dir=WEIGHTS_DIR,
            source="local",
        )
        normal_image = nirne(image, resolution=768, match_input_resolution=True, data_type="object")
        del nirne
        torch.cuda.empty_cache()

        # --- Phase 2: Hi3DGen 3D generation ---
        # Delete each model from pipe.models after its step so pipe.device keeps
        # returning CUDA (dict-order based) and GPU memory is freed incrementally.
        from hi3dgen.pipelines import Hi3DGenPipeline
        pipe = Hi3DGenPipeline.from_pretrained(trellis_local)
        pipe.cuda()
        with torch.no_grad():
            cond = pipe.get_cond([normal_image])
            del pipe.models["image_cond_model"]
            torch.cuda.empty_cache()

            torch.manual_seed(seed)
            coords = pipe.sample_sparse_structure(cond, 1, {"steps": ss_steps, "cfg_strength": ss_guidance})
            del pipe.models["sparse_structure_flow_model"]
            del pipe.models["sparse_structure_decoder"]
            torch.cuda.empty_cache()

            slat = pipe.sample_slat(cond, coords, {"steps": slat_steps, "cfg_strength": slat_guidance})
            del pipe.models["slat_flow_model"]
            torch.cuda.empty_cache()

            outputs = pipe.decode_slat(slat, ["mesh"])

        trimesh_mesh = outputs["mesh"][0].to_trimesh(transform_pose=True)
        output_path = os.path.join(tmp_dir, "output.glb")
        trimesh_mesh.export(output_path)
        with open(output_path, "rb") as f:
            glb_bytes = f.read()
        del pipe
        torch.cuda.empty_cache()

    return glb_bytes


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    ss_steps: int = Query(default=50, ge=1, le=100),
    ss_guidance: float = Query(default=3.0, ge=0.0),
    slat_steps: int = Query(default=6, ge=1, le=50),
    slat_guidance: float = Query(default=3.0, ge=0.0),
    seed: int = Query(default=42),
):
    image_data = await file.read()
    async with inference_lock:
        glb_bytes = await asyncio.get_event_loop().run_in_executor(
            None, _run_inference, image_data, ss_steps, ss_guidance, slat_steps, slat_guidance, seed
        )
    return Response(
        content=glb_bytes,
        media_type="model/gltf-binary",
        headers={"Content-Disposition": "attachment; filename=\"output.glb\""},
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8096)
