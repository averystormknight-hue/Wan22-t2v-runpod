FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

# Set environment and install required system dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git curl ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Clone and set up ComfyUI framework and dependencies
WORKDIR /comfyui
RUN git clone --branch <pinned-commit-or-branch> https://github.com/comfyanonymous/ComfyUI.git ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Install custom nodes and their dependencies
RUN git clone --branch <optional-commit> https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git custom_nodes/ComfyUI-VideoHelperSuite
RUN git clone --branch <optional-commit> https://github.com/kijai/ComfyUI-KJNodes.git custom_nodes/ComfyUI-KJNodes
RUN git clone --branch <optional-commit> https://github.com/kijai/ComfyUI-WanVideoWrapper.git custom_nodes/ComfyUI-WanVideoWrapper

RUN for NODE in /comfyui/custom_nodes/*/requirements.txt; do \
    if [ -f "$NODE" ]; then echo "Installing dependencies for $NODE"; pip3 install --no-cache-dir -r "$NODE"; fi; \
done

# Set up application directory and install any necessary app-specific dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Ensure entrypoint script is executable
RUN chmod +x entrypoint.sh

# Start the application using the entrypoint script
CMD ["/app/entrypoint.sh"]