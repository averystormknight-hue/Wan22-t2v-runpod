#!/usr/bin/env bash
set -e

if [ -d /runpod-volume ]; then
  mkdir -p /runpod-volume/models
  mkdir -p /runpod-volume/loras

  if [ -e /comfyui/models ]; then
    rm -rf /comfyui/models
  fi
  ln -s /runpod-volume/models /comfyui/models

  mkdir -p /comfyui/models/loras
  rm -rf /comfyui/models/loras
  ln -s /runpod-volume/loras /comfyui/models/loras
fi

mkdir -p /comfyui/input
mkdir -p /comfyui/output

python3 /comfyui/main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch &
python3 -u /app/handler.py
