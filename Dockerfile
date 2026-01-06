FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1

# System deps (includes common runtime libs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git curl ffmpeg \
    libgl1 libglib2.0-0 fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# ComfyUI
WORKDIR /comfyui
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ./

# CUDA-enabled torch stack (cu121) before other Python deps
RUN pip3 install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 \
    --extra-index-url https://download.pytorch.org/whl/cu121

# ComfyUI requirements
RUN pip3 install -r requirements.txt

# Custom nodes (default branches; pin commits if you need reproducibility)
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git custom_nodes/ComfyUI-VideoHelperSuite
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git custom_nodes/ComfyUI-KJNodes
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git custom_nodes/ComfyUI-WanVideoWrapper

# Install node-specific deps when present
RUN for NODE in /comfyui/custom_nodes/*/requirements.txt; do \
    if [ -f "$NODE" ]; then echo "Installing dependencies for $NODE"; pip3 install -r "$NODE"; fi; \
done

# App layer
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY . .

# Ensure entrypoint script is executable
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
