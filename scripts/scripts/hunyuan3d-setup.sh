#!/usr/bin/env bash
set -e

DOCKERFILE_DIR="$(dirname "$(readlink -f "$0")")/../../docker/hunyuan3d"
DOCKERFILE_DIR="$(realpath "$DOCKERFILE_DIR")"

echo "=== Hunyuan3D Setup ==="
echo ""

echo "[1/1] Building Docker image (may take 15-30 minutes first time)..."
docker build -t hunyuan3d-api "$DOCKERFILE_DIR"

echo ""
echo "=== Done! ==="
echo ""
echo "Start API server:"
echo "  hunyuan3d start"
echo ""
echo "Model weights (~8GB) will be downloaded from HuggingFace on first start."
echo "API: http://localhost:8094"
echo "  GET  /health"
echo "  POST /generate  (multipart: file=<image>, num_inference_steps, guidance_scale, seed)"
