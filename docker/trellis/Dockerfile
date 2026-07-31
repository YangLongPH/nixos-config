FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0" \
    FORCE_CUDA=1 \
    CPATH="/usr/local/cuda/include" \
    PATH="/usr/local/cuda/bin:${PATH}" \
    ATTN_BACKEND=flash-attn \
    SPCONV_ALGO=native

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-dev python3.10-distutils \
    python3-pip git curl build-essential ninja-build \
    libglib2.0-0 libsm6 libxrender1 libxext6 libgomp1 libgl1 libopengl0 \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

WORKDIR /app

RUN git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git .

# PyTorch with CUDA 12.4
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# spconv — sparse convolution (TRELLIS core dependency)
RUN pip install --no-cache-dir spconv-cu124

# TRELLIS dependencies
RUN pip install --no-cache-dir \
    pillow imageio imageio-ffmpeg tqdm easydict \
    opencv-python-headless scipy ninja \
    trimesh xatlas pymeshlab \
    transformers diffusers accelerate \
    huggingface_hub einops omegaconf \
    plyfile jaxtyping

# flash-attn for attention (optional but faster)
RUN pip install --no-cache-dir flash-attn --no-build-isolation || \
    pip install --no-cache-dir xformers

# nvdiffrast — differentiable rasterizer (TRELLIS texture baking)
RUN pip install --no-cache-dir git+https://github.com/NVlabs/nvdiffrast.git --no-build-isolation

# utils3d — copy module directly (moderngl dep breaks pip install in headless env)
RUN git clone -q https://github.com/EasternJournalist/utils3d.git /tmp/utils3d_src \
    && cp -r /tmp/utils3d_src/utils3d /usr/local/lib/python3.10/dist-packages/ \
    && rm -rf /tmp/utils3d_src

# kaolin for sparse operations
RUN pip install --no-cache-dir kaolin -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.4.0_cu124.html || \
    echo "kaolin install skipped"

# rembg for background removal
RUN pip install --no-cache-dir "rembg[cpu]"

# open3d for 3D processing
RUN pip install --no-cache-dir open3d

# API server
RUN pip install --no-cache-dir fastapi "uvicorn[standard]" python-multipart

COPY server.py .

EXPOSE 8097

CMD ["python3", "server.py"]
