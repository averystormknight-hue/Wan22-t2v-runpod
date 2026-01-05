FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    python3 python3-pip git curl ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /comfyui
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ./
RUN pip3 install --no-cache-dir -r /comfyui/requirements.txt

# Custom nodes required by the workflow
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git /comfyui/custom_nodes/ComfyUI-VideoHelperSuite
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git /comfyui/custom_nodes/ComfyUI-KJNodes
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git /comfyui/custom_nodes/ComfyUI-WanVideoWrapper

RUN if [ -f /comfyui/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt ]; then pip3 install --no-cache-dir -r /comfyui/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt; fi
RUN if [ -f /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt ]; then pip3 install --no-cache-dir -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt; fi
RUN if [ -f /comfyui/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt ]; then pip3 install --no-cache-dir -r /comfyui/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt; fi

WORKDIR /app
COPY requirements.txt /app/
RUN pip3 install --no-cache-dir -r /app/requirements.txt

COPY . /app
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
