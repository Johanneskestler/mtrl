# Dockerfile for MTRL (Multi-Task Reinforcement Learning) on GPU Cluster
# Based on Python 3.12 with CUDA 12.1 support for JAX
# Target: TU Wien DataLAB Cluster (A40 GPU)

FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

LABEL maintainer="Johannes" \
      description="MTRL Multi-Task RL Training on GPU Cluster"

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Vienna

# Install Python 3.12 and essential tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && wget https://bootstrap.pypa.io/get-pip.py \
    && python3.12 get-pip.py \
    && rm get-pip.py \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install system dependencies for headless rendering and development
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Graphics and rendering (for headless MuJoCo with EGL + OSMesa fallback)
    libgl1-mesa-glx \
    libglfw3 \
    libglfw3-dev \
    libxinerama1 \
    libxrandr2 \
    libxcursor1 \
    libosmesa6 \
    libosmesa6-dev \
    libglu1-mesa \
    libgles2-mesa \
    # EGL for GPU-accelerated headless rendering
    libegl1-mesa \
    libegl1-mesa-dev \
    libgbm1 \
    # X11 and Xvfb for headless rendering fallback
    xvfb \
    x11-utils \
    x11-common \
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

# Set environment variables for headless rendering AND GPU
# Use EGL for GPU-accelerated headless rendering (much faster than osmesa)
ENV MUJOCO_GL=egl \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH \
    PYTHONUNBUFFERED=1 \
    CUDA_VISIBLE_DEVICES=0 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

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

# Copy entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /workspace/mtrl

# Health check: verify key packages (skip metaworld import - needs rendering)
RUN python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')" && \
    python -c "import gymnasium; print(f'Gymnasium OK')" && \
    python -c "import optax; print(f'Optax OK')" && \
    python -c "import wandb; print(f'W&B OK')"

# Use custom entrypoint for environment setup
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]

