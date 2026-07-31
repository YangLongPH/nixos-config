FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0" \
    FORCE_CUDA=1 \
    CPATH="/usr/local/cuda/include" \
    PATH="/usr/local/cuda/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-dev python3.10-distutils \
    python3-pip git curl build-essential ninja-build \
    libglib2.0-0 libsm6 libxrender1 libxext6 libgomp1 libgl1 libopengl0 \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

WORKDIR /app

RUN git clone https://github.com/VAST-AI-Research/TripoSG.git .

# Install PyTorch with CUDA 12.4 before other packages (diso needs torch at compile time)
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Install TripoSG requirements (without the numpy version pin to avoid conflicts)
RUN pip install --no-cache-dir \
    diffusers transformers einops huggingface_hub \
    opencv-python trimesh omegaconf scikit-image \
    numpy peft jaxtyping typeguard pymeshlab

# Install diso separately — it compiles a CUDA extension and needs TORCH_CUDA_ARCH_LIST
RUN pip install --no-cache-dir diso

# Install API server dependencies
RUN pip install --no-cache-dir fastapi "uvicorn[standard]" python-multipart

COPY server.py .

EXPOSE 8093

CMD ["python3", "server.py"]
