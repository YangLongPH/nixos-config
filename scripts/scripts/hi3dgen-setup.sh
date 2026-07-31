#!/usr/bin/env bash
set -e

DOCKERFILE_DIR="$(dirname "$(readlink -f "$0")")/../../docker/hi3dgen"
DOCKERFILE_DIR="$(realpath "$DOCKERFILE_DIR")"

echo "=== Hi3DGen Setup ==="
echo ""

echo "[1/1] Building Docker image (may take 15-30 minutes first time)..."
docker build -t hi3dgen-api "$DOCKERFILE_DIR"

echo ""
echo "=== Done! ==="
echo ""
echo "Start API server:"
echo "  hi3dgen start"
echo ""
echo "Model weights will be downloaded from HuggingFace on first start."
echo "API: http://localhost:8096"
echo "  GET  /health"
echo "  POST /generate  (multipart: file=<image>, num_inference_steps, guidance_scale, seed)"
