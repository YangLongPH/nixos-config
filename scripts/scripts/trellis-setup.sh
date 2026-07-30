#!/usr/bin/env bash
set -e

TRELLIS_API_DIR="$HOME/.local/share/trellis-api"
TRELLIS_ADDON_DIR="$HOME/.local/share/trellis-blender"

echo "=== TRELLIS Setup ==="
echo ""

# 1. Clone API server
if [ ! -d "$TRELLIS_API_DIR" ]; then
    echo "[1/3] Cloning TRELLIS API server..."
    git clone https://github.com/FishWoWater/TRELLIS-API-Server "$TRELLIS_API_DIR"
else
    echo "[1/3] Updating TRELLIS API server..."
    git -C "$TRELLIS_API_DIR" pull
fi

# 2. Build Docker image
echo ""
echo "[2/3] Building Docker image (may take 10-20 minutes first time)..."
docker build -t trellis-api "$TRELLIS_API_DIR"

# 3. Clone Blender addon
echo ""
if [ ! -d "$TRELLIS_ADDON_DIR" ]; then
    echo "[3/3] Cloning Blender addon..."
    git clone https://github.com/FishWoWater/trellis_blender "$TRELLIS_ADDON_DIR"
else
    echo "[3/3] Updating Blender addon..."
    git -C "$TRELLIS_ADDON_DIR" pull
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Start API server:"
echo "  trellis start"
echo ""
echo "Install Blender addon:"
echo "  Path: $TRELLIS_ADDON_DIR/trellis_for_blender.py"
echo "  Blender → Edit → Preferences → Add-ons → Install → chọn file trên"
echo "  Enable: '3D View: TRELLIS'"
echo "  Nhấn N trong viewport → tab TRELLIS → API URL: http://localhost:8092"
