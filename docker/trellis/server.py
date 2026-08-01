import asyncio
import os
import sys
import tempfile

import numpy as np
import torch
import trimesh
import uvicorn
from fastapi import FastAPI, File, Query, UploadFile
from fastapi.responses import Response
from PIL import Image

CACHE_DIR = os.environ.get("HUGGINGFACE_HUB_CACHE", "/root/.cache/huggingface")
MODEL_REPO = "JeffreyXiang/TRELLIS-image-large"

inference_lock = asyncio.Lock()

app = FastAPI(title="TRELLIS API", version="1.0.0")


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": False}


def _run_inference(image_data, ss_steps, ss_guidance, slat_steps, slat_guidance, seed):
    sys.path.insert(0, "/app")
    os.environ["SPCONV_ALGO"] = "native"

    from trellis.pipelines import TrellisImageTo3DPipeline

    model_dir = os.path.join(CACHE_DIR, "TRELLIS")
    if not os.path.exists(os.path.join(model_dir, "pipeline.json")):
        from huggingface_hub import snapshot_download
        model_dir = snapshot_download(repo_id=MODEL_REPO, local_dir=model_dir)

    with tempfile.TemporaryDirectory() as tmp_dir:
        img_path = os.path.join(tmp_dir, "input.png")
        with open(img_path, "wb") as f:
            f.write(image_data)

        image = Image.open(img_path).convert("RGBA")
        image = TrellisImageTo3DPipeline.preprocess_image(None, image)

        torch.cuda.empty_cache()
        pipe = TrellisImageTo3DPipeline.from_pretrained(model_dir)
        pipe.cuda()

        # Delete unused decoders immediately (we only need mesh)
        for key in ['slat_decoder_gs', 'slat_decoder_rf']:
            if key in pipe.models:
                del pipe.models[key]
        torch.cuda.empty_cache()

        with torch.no_grad():
            # Step 1: encode image → delete image_cond_model
            cond = pipe.get_cond([image])
            del pipe.models['image_cond_model']
            torch.cuda.empty_cache()

            # Step 2: sample sparse structure → delete flow + decoder
            torch.manual_seed(seed)
            coords = pipe.sample_sparse_structure(
                cond, 1,
                {"steps": ss_steps, "cfg_strength": ss_guidance},
            )
            del pipe.models['sparse_structure_flow_model']
            del pipe.models['sparse_structure_decoder']
            torch.cuda.empty_cache()

            # Step 3: sample slat → delete slat_flow_model
            slat = pipe.sample_slat(
                cond, coords,
                {"steps": slat_steps, "cfg_strength": slat_guidance},
            )
            del pipe.models['slat_flow_model']
            torch.cuda.empty_cache()

            # Step 4: decode mesh
            outputs = pipe.decode_slat(slat, ['mesh'])

        del pipe
        torch.cuda.empty_cache()

        mesh_result = outputs["mesh"][0]
        verts = mesh_result.vertices.cpu().numpy().astype(np.float32)
        faces = mesh_result.faces.cpu().numpy()
        mesh = trimesh.Trimesh(vertices=verts, faces=faces, process=False)

        output_path = os.path.join(tmp_dir, "output.glb")
        mesh.export(output_path)
        with open(output_path, "rb") as f:
            return f.read()


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    ss_steps: int = Query(default=12, ge=1, le=50),
    ss_guidance: float = Query(default=7.5, ge=0.0),
    slat_steps: int = Query(default=12, ge=1, le=50),
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
        headers={"Content-Disposition": 'attachment; filename="output.glb"'},
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8097)
