# Dockerfile for MTRL (Multi-Task Reinforcement Learning) on GPU Cluster
# Based on PyTorch GPU image with JAX support
# Target: TU Wien DataLAB Cluster (A40 GPU)

FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

LABEL maintainer="Johannes" \
      description="MTRL Multi-Task RL Training on GPU Cluster"

# Install system dependencies for headless rendering and development
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Graphics and rendering (for headless MuJoCo)
    libgl1-mesa-glx \
    libglfw3 \
    libglfw3-dev \
    libxinerama1 \
    libxrandr2 \
    libxcursor1 \
    libosmesa6 \
    libosmesa6-dev \
    # Build tools
    build-essential \
    git \
    wget \
    curl \
    # Development tools
    nano \
    htop \
    vim \
    # Additional utilities
    openssh-client \
    rsync \
    # Required for some Python packages
    libhdf5-dev \
    libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for headless rendering
ENV MUJOCO_GL=osmesa \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH \
    PYTHONUNBUFFERED=1 \
    CUDA_VISIBLE_DEVICES=0

# Upgrade pip and install Python dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements file (will be provided at build time)
COPY requirements.txt /tmp/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Create workspace directories
RUN mkdir -p /workspace/mtrl \
    && mkdir -p /workspace/logs \
    && mkdir -p /workspace/models \
    && mkdir -p /workspace/wandb_cache

# Set working directory
WORKDIR /workspace/mtrl

# Health check: verify CUDA and key packages
RUN python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')" && \
    python -c "import gymnasium; print(f'Gymnasium OK')" && \
    python -c "import metaworld; print(f'Meta-World OK')" && \
    python -c "import wandb; print(f'W&B OK')"

# Default command
ENTRYPOINT ["python"]
CMD ["--version"]
