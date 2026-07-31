FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive     PYTHONUNBUFFERED=1     CUDA_HOME=/usr/local/cuda

RUN apt-get update && apt-get install -y --no-install-recommends     python3.10 python3.10-dev python3.10-distutils     python3-pip git curl build-essential     libglib2.0-0 libsm6 libxrender1 libxext6 libgomp1     libgl1-mesa-glx libgles2     && rm -rf /var/lib/apt/lists/*     && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1     && update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

WORKDIR /app

RUN git clone https://github.com/TencentARC/InstantMesh.git .

RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

RUN pip install --no-cache-dir einops omegaconf huggingface_hub accelerate pillow numpy

RUN pip install --no-cache-dir diffusers transformers

RUN pip install --no-cache-dir trimesh pymeshlab imageio imageio-ffmpeg

RUN pip install --no-cache-dir xformers --index-url https://download.pytorch.org/whl/cu124

RUN pip install --no-cache-dir rembg onnxruntime-gpu || pip install --no-cache-dir rembg onnxruntime

RUN pip install --no-cache-dir fastapi "uvicorn[standard]" python-multipart

COPY server.py .

EXPOSE 8095

CMD ["python3", "server.py"]
