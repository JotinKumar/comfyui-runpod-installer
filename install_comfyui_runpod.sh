#!/bin/bash
# ComfyUI Installation Script for RunPod.io with 5090 (CUDA 12.8) Support and uv Virtual Environment

echo "========================================"
echo "🚀 Starting ComfyUI setup for RunPod.io..."
echo "========================================"

# Set UV_LINK_MODE to copy to avoid hardlinking issues across filesystems
export UV_LINK_MODE=copy

# Install uv if not present using the official installer
echo "----------------------------------------"
echo "📦 Installing uv package manager..."
echo "----------------------------------------"
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Wait for uv environment file to exist (max 15 seconds)
    for i in {1..15}; do
        if [ -f "$HOME/.local/bin/env" ]; then
            source "$HOME/.local/bin/env"
            echo "✅ uv environment loaded successfully"
            break
        fi
        echo "Waiting for uv environment... ($i/15)"
        sleep 1
    done
    
    # Fallback if env file not found - add uv bin directory to PATH
    if ! command -v uv &>/dev/null; then
        echo "Warning: uv env file not found. Setting PATH manually."
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Verify uv installation
    if ! command -v uv &>/dev/null; then
        echo "Error: uv installation failed!"
        exit 1
    fi
    
    echo "✅ uv installed successfully"
else
    echo "✅ uv already installed"
fi

# Create base directories
echo "----------------------------------------"
echo "📁 Creating base directories..."
echo "----------------------------------------"
mkdir -p /workspace/ComfyUI

# Clone ComfyUI repository (or update if exists)
echo "----------------------------------------"
echo "📥 Cloning or updating ComfyUI repository..."
echo "----------------------------------------"
if [ ! -d "/workspace/ComfyUI/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
    echo "✅ ComfyUI cloned successfully"
else
    echo "✅ ComfyUI already exists, updating..."
    cd /workspace/ComfyUI
    git pull
fi

# Create virtual environment with uv
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

# Activate virtual environment
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

# Ensure pip is properly installed/upgraded
echo "----------------------------------------"
echo "📦 Upgrading pip, setuptools, wheel using uv..."
echo "----------------------------------------"
uv pip install --upgrade pip setuptools wheel
echo "✅ pip upgraded"

# Install PyTorch with CUDA 12.8 support for Nvidia 5090
echo "----------------------------------------"
echo "🔥 Installing PyTorch with CUDA 12.8 for 5090 support..."
echo "----------------------------------------"
uv pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
echo "✅ PyTorch with CUDA 12.8 installed"

# Install ComfyUI requirements
echo "----------------------------------------"
echo "📦 Installing ComfyUI requirements..."
echo "----------------------------------------"
uv pip install -r requirements.txt
echo "✅ ComfyUI requirements installed"

# Install onnxruntime-gpu for acceleration in certain nodes like DWPose
echo "----------------------------------------"
echo "📦 Installing onnxruntime-gpu..."
echo "----------------------------------------"
uv pip install onnxruntime-gpu
echo "✅ onnxruntime-gpu installed"

# Install essential custom nodes function
install_custom_node() {
    local repo_url=$1
    local node_name=$2
    local target_dir="custom_nodes/${node_name}"
    
    mkdir -p custom_nodes
    
    if [ ! -d "${target_dir}/.git" ]; then
        echo "📥 Installing ${node_name}..."
        git clone "${repo_url}" "${target_dir}"
        if [ -f "${target_dir}/requirements.txt" ]; then
            uv pip install -r "${target_dir}/requirements.txt"
        fi
        echo "✅ ${node_name} installed successfully"
    else
        echo "✅ ${node_name} already exists, updating..."
        cd "${target_dir}"
        git pull
        if [ -f "requirements.txt" ]; then
            uv pip install -r requirements.txt
        fi
        cd /workspace/ComfyUI
    fi
}

echo "----------------------------------------"
echo "🔌 Installing essential custom nodes..."
echo "----------------------------------------"

install_custom_node "https://github.com/ltdrdata/ComfyUI-Manager.git" "ComfyUI-Manager"
install_custom_node "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git" "ComfyUI_IPAdapter_plus"
install_custom_node "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "ComfyUI-Impact-Pack"
install_custom_node "https://github.com/Fannovel16/comfyui_controlnet_aux.git" "comfyui_controlnet_aux"
install_custom_node "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git" "ComfyUI-AnimateDiff-Evolved"
install_custom_node "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git" "ComfyUI-Custom-Scripts"
install_custom_node "https://github.com/WASasquatch/was-node-suite-comfyui.git" "was-node-suite-comfyui"
install_custom_node "https://github.com/rgthree/rgthree-comfy.git" "rgthree-comfy"

# Create model directories
echo "----------------------------------------"
echo "📁 Creating model directories..."
echo "----------------------------------------"
mkdir -p models/checkpoints models/loras models/vae models/clip models/unet models/controlnet models/upscale_models models/embeddings models/ipadapter models/animatediff_models models/ultralytics_bbox models/ultralytics_segm models/sams models/mmdets models/insightface
echo "✅ Model directories created"

# Create startup script
echo "----------------------------------------"
echo "📝 Creating startup script..."
echo "----------------------------------------"
cat > start_comfyui.sh << 'EOF'
#!/bin/bash
cd /workspace/ComfyUI
source .venv/bin/activate
python main.py --listen --port 8188
EOF
chmod +x start_comfyui.sh
echo "✅ Startup script created"

# Create a systemd service (optional, if you have permissions)
echo "----------------------------------------"
echo "🔧 Creating systemd service for ComfyUI..."
echo "----------------------------------------"
if [ -w /etc/systemd/system ]; then
    cat > /etc/systemd/system/comfyui.service << EOF
[Unit]
Description=ComfyUI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/workspace/ComfyUI
ExecStart=/bin/bash -c 'source $HOME/.local/bin/env && source .venv/bin/activate && python main.py --listen --port 8188'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable comfyui
    echo "✅ Systemd service created and enabled"
else
    echo "⚠️ Skipping systemd service creation (no permission)"
fi

# Create an instruction file for user
echo "----------------------------------------"
echo "📝 Creating instruction file..."
echo "----------------------------------------"
cat > /workspace/Instructions.txt << EOF
========================================
ComfyUI Setup Instructions
========================================

To start ComfyUI:
1. Navigate to /workspace/ComfyUI
2. Activate the virtual environment:
   source .venv/bin/activate
3. Run the startup script:
   ./start_comfyui.sh
   OR manually run:
   python main.py --listen --port 8188
   OR if systemd service created, run:
   systemctl start comfyui

ComfyUI will be available at: http://localhost:8188

========================================
Model Download Instructions
========================================

Download recommended models:

1. SDXL Turbo (Small, fast model):
   wget https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors -O /workspace/ComfyUI/models/checkpoints/sd_xl_turbo_1.0.safetensors

2. AnimateDiff Motion Model:
   wget https://huggingface.co/guoyww/animatediff/resolve/main/v3_sd15_mm.ckpt -O /workspace/ComfyUI/models/animatediff_models/v3_sd15_mm.ckpt

3. SD 1.5 Base Model:
   wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.ckpt -O /workspace/ComfyUI/models/checkpoints/v1-5-pruned.ckpt

4. VAE for SD 1.5:
   wget https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.ckpt -O /workspace/ComfyUI/models/vae/vae-ft-mse-840000-ema-pruned.ckpt

5. ControlNet Models:
   wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth -O /workspace/ComfyUI/models/controlnet/control_v11p_sd15_canny.pth
   wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth -O /workspace/ComfyUI/models/controlnet/control_v11f1p_sd15_depth.pth

========================================
Additional Tips
========================================

- Use wget --continue to resume large downloads.
- Check console logs when starting ComfyUI to verify models are loaded.
- ComfyUI Manager node supports installing nodes and extra models via the UI.
- Ensure enough disk space for models (several GBs).
- If uv or virtual environment issues occur, source uv env manually:
  source $HOME/.local/bin/env
========================================
EOF

echo "✅ Instruction file created at /workspace/Instructions.txt"

# Deactivate virtual environment
echo "----------------------------------------"
echo "🔄 Deactivating virtual environment..."
echo "----------------------------------------"
deactivate
echo "✅ Virtual environment deactivated"

# Remove the setup script itself
echo "----------------------------------------"
echo "🧹 Removing setup script install_comfyui_runpod.sh..."
echo "----------------------------------------"
rm -- /workspace/install_comfyui_runpod.sh

echo ""
echo "========================================"
echo "✨ Setup complete! ✨"
echo "========================================"
echo ""


echo "ComfyUI has been installed successfully!"
echo "Check /workspace/Instructions.txt for how to start ComfyUI and download models."
echo ""
echo "This setup uses:"
echo "- Python 3.11"
echo "- CUDA 12.8 (for Nvidia 5090)"
echo "- PyTorch nightly build with CUDA 12.8 support"
echo "- uv virtual environment manager"
echo "- Essential custom nodes pre-installed"
echo ""

# Start ComfyUI automatically
echo "----------------------------------------"
echo "🚀 Starting ComfyUI..."
echo "----------------------------------------"
cd /workspace/ComfyUI
source .venv/bin/activate
python main.py --listen --port 8188



