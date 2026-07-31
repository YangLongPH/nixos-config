import asyncio
import os
import sys
import tempfile
from contextlib import asynccontextmanager
from typing import Optional

# scripts/ contains briarmbg.py and image_process.py
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "scripts"))

import numpy as np
import pymeshlab
import torch
import trimesh
import uvicorn
from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.responses import Response
from huggingface_hub import snapshot_download

from briarmbg import BriaRMBG
from image_process import prepare_image
from triposg.pipelines.pipeline_triposg import TripoSGPipeline

WEIGHTS_DIR = os.environ.get("PRETRAINED_WEIGHTS_PATH", "/app/pretrained_weights")
TRIPOSG_WEIGHTS = os.path.join(WEIGHTS_DIR, "TripoSG")
RMBG_WEIGHTS = os.path.join(WEIGHTS_DIR, "RMBG-1.4")

pipe: Optional[TripoSGPipeline] = None
rmbg_net: Optional[BriaRMBG] = None
inference_lock = asyncio.Lock()


@asynccontextmanager
async def lifespan(app: FastAPI):
    global pipe, rmbg_net
    snapshot_download(repo_id="VAST-AI/TripoSG", local_dir=TRIPOSG_WEIGHTS)
    snapshot_download(repo_id="briaai/RMBG-1.4", local_dir=RMBG_WEIGHTS)
    device, dtype = "cuda", torch.float16
    rmbg_net = BriaRMBG.from_pretrained(RMBG_WEIGHTS).to(device).eval()
    pipe = TripoSGPipeline.from_pretrained(TRIPOSG_WEIGHTS).to(device, dtype)
    yield


def simplify_mesh(mesh: trimesh.Trimesh, n_faces: int) -> trimesh.Trimesh:
    if mesh.faces.shape[0] <= n_faces:
        return mesh
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(vertex_matrix=mesh.vertices, face_matrix=mesh.faces))
    ms.meshing_merge_close_vertices()
    ms.meshing_decimation_quadric_edge_collapse(targetfacenum=n_faces)
    m = ms.current_mesh()
    return trimesh.Trimesh(vertices=m.vertex_matrix(), faces=m.face_matrix())


app = FastAPI(title="TripoSG API", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": pipe is not None}


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    num_inference_steps: int = Query(default=50, ge=1, le=200),
    guidance_scale: float = Query(default=7.0, ge=0.0),
    seed: int = Query(default=42),
    faces: int = Query(default=-1),
    octree_depth: int = Query(default=8, ge=6, le=10),
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

            img_pil = prepare_image(img_path, bg_color=np.array([1.0, 1.0, 1.0]), rmbg_net=rmbg_net)

            with torch.no_grad():
                outputs = pipe(
                    image=img_pil,
                    generator=torch.Generator(device=pipe.device).manual_seed(seed),
                    num_inference_steps=num_inference_steps,
                    guidance_scale=guidance_scale,
                    flash_octree_depth=octree_depth,
                    dense_octree_depth=max(6, octree_depth - 1),
                    hierarchical_octree_depth=octree_depth,
                ).samples[0]

            mesh = trimesh.Trimesh(outputs[0].astype(np.float32), np.ascontiguousarray(outputs[1]))
            if faces > 0:
                mesh = simplify_mesh(mesh, faces)

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
    uvicorn.run(app, host="0.0.0.0", port=8093)
