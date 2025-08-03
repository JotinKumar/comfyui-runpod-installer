#!/bin/bash
# ComfyUI Installation Script for RunPod.io with uv package manager support

echo "========================================"
echo "🚀 Starting ComfyUI setup for RunPod.io..."
echo "========================================"

export UV_LINK_MODE=copy

# Install uv if not present using the official installer
echo "----------------------------------------"
echo "📦 Installing uv package manager..."
echo "----------------------------------------"
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Wait up to 15 seconds for uv env file to load
    for i in {1..15}; do
        if [ -f "$HOME/.local/bin/env" ]; then
            source "$HOME/.local/bin/env"
            echo "✅ uv environment loaded successfully"
            break
        fi
        echo "Waiting for uv environment... ($i/15)"
        sleep 1
    done

    # Fallback if env file not found or uv command still missing
    if ! command -v uv &>/dev/null; then
        echo "Warning: uv env file not found or uv not found in PATH. Adding manually."
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if ! command -v uv &>/dev/null; then
        echo "Error: uv installation failed!"
        exit 1
    fi
    echo "✅ uv installed successfully"
else
    echo "✅ uv already installed"
fi

# Continue with ComfyUI installation using uv

echo "----------------------------------------"
echo "📁 Creating base directories..."
echo "----------------------------------------"
mkdir -p /workspace/ComfyUI

echo "----------------------------------------"
echo "📥 Cloning/Updating ComfyUI repository..."
echo "----------------------------------------"
if [ ! -d "/workspace/ComfyUI/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
    echo "✅ ComfyUI cloned successfully"
else
    cd /workspace/ComfyUI
    git pull
    echo "✅ ComfyUI updated successfully"
fi

echo "----------------------------------------"
echo "🐍 Creating virtual environment with uv..."
echo "----------------------------------------"
cd /workspace/ComfyUI
if [ ! -d ".venv" ]; then
    uv venv --python 3.11 --seed
    echo "✅ Virtual environment created with Python 3.11"
else
    echo "✅ Virtual environment already exists"
fi

echo "----------------------------------------"
echo "🔄 Activating virtual environment..."
echo "----------------------------------------"
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "Error: Virtual environment activation script not found"
    exit 1
fi

echo "----------------------------------------"
echo "📦 Upgrading pip, setuptools, wheel using uv..."
echo "----------------------------------------"
uv pip install --upgrade pip setuptools wheel
echo "✅ pip upgraded"

echo "----------------------------------------"
echo "🔥 Installing PyTorch with CUDA 12.8 support..."
echo "----------------------------------------"
uv pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
echo "✅ PyTorch installed"

echo "----------------------------------------"
echo "📦 Installing ComfyUI requirements..."
echo "----------------------------------------"
uv pip install -r requirements.txt
echo "✅ ComfyUI requirements installed"

echo "----------------------------------------"
echo "📦 Installing onnxruntime-gpu..."
echo "----------------------------------------"
uv pip install onnxruntime-gpu
echo "✅ onnxruntime-gpu installed"

# (Continue with custom nodes installation similarly using uv for pip installs)

# At the end, deactivate virtualenv
deactivate

echo "========================================"
echo "✨ Setup complete! ✨"
echo "========================================"
