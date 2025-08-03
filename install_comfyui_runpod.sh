#!/bin/bash
# ComfyUI Installation Script for RunPod.io with 5090 Support
# This script installs ComfyUI with essential custom nodes using uv virtual environment

echo "========================================"
echo "🚀 Starting ComfyUI setup for RunPod.io..."
echo "========================================"

# Install uv if not present
echo "----------------------------------------"
echo "📦 Installing uv package manager..."
echo "----------------------------------------"
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env
    echo "✅ uv installed successfully"
else
    echo "✅ uv already installed"
fi

# Create base directories
echo "----------------------------------------"
echo "📁 Creating base directories..."
echo "----------------------------------------"
mkdir -p /workspace/ComfyUI
mkdir -p /workspace/models

# Clone ComfyUI repository
echo "----------------------------------------"
echo "📥 Cloning ComfyUI repository..."
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
    uv venv --python 3.11
    echo "✅ Virtual environment created with Python 3.11"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
echo "----------------------------------------"
echo "🔄 Activating virtual environment..."
echo "----------------------------------------"
source .venv/bin/activate
echo "✅ Virtual environment activated"

# Install PyTorch with CUDA 12.8 support for 5090
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

# Install essential custom nodes
echo "----------------------------------------"
echo "🔌 Installing essential custom nodes..."
echo "----------------------------------------"

# Create custom_nodes directory if it doesn't exist
mkdir -p custom_nodes

# Function to install custom node
install_custom_node() {
    local repo_url=$1
    local node_name=$2
    local target_dir="custom_nodes/${node_name}"
    
    if [ ! -d "${target_dir}/.git" ]; then
        echo "📥 Installing ${node_name}..."
        git clone ${repo_url} ${target_dir}
        if [ -f "${target_dir}/requirements.txt" ]; then
            uv pip install -r ${target_dir}/requirements.txt
        fi
        echo "✅ ${node_name} installed successfully"
    else
        echo "✅ ${node_name} already exists, updating..."
        cd ${target_dir}
        git pull
        if [ -f "requirements.txt" ]; then
            uv pip install -r requirements.txt
        fi
        cd /workspace/ComfyUI
    fi
}

# Install ComfyUI Manager (most essential)
install_custom_node "https://github.com/ltdrdata/ComfyUI-Manager.git" "ComfyUI-Manager"

# Install other essential custom nodes
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
mkdir -p models/checkpoints
mkdir -p models/loras
mkdir -p models/vae
mkdir -p models/clip
mkdir -p models/unet
mkdir -p models/controlnet
mkdir -p models/upscale_models
mkdir -p models/embeddings
mkdir -p models/ipadapter
mkdir -p models/animatediff_models
mkdir -p models/ultralytics_bbox
mkdir -p models/ultralytics_segm
mkdir -p models/sams
mkdir -p models/mmdets
mkdir -p models/insightface
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

# Deactivate virtual environment
echo "----------------------------------------"
echo "🔄 Deactivating virtual environment..."
echo "----------------------------------------"
deactivate
echo "✅ Virtual environment deactivated"

echo ""
echo "========================================"
echo "✨ Setup complete! ✨"
echo "========================================"
echo ""
echo "To start ComfyUI:"
echo "1. Navigate to /workspace/ComfyUI"
echo "2. Activate the virtual environment: source .venv/bin/activate"
echo "3. Run the startup script: ./start_comfyui.sh"
echo "   OR manually run: python main.py --listen --port 8188"
echo ""
echo "ComfyUI will be available at: http://localhost:8188"
echo ""
echo "For 5090 support, this installation uses:"
echo "- Python 3.11"
echo "- CUDA 12.8"
echo "- PyTorch nightly build with CUDA 12.8 support"
echo "- uv virtual environment manager"
echo ""
echo "Essential custom nodes installed:"
echo "- ComfyUI-Manager (node management)"
echo "- ComfyUI_IPAdapter_plus (IP-Adapter support)"
echo "- ComfyUI-Impact-Pack (detailer and detector nodes)"
echo "- comfyui_controlnet_aux (ControlNet preprocessors)"
echo "- ComfyUI-AnimateDiff-Evolved (animation support)"
echo "- ComfyUI-Custom-Scripts (UI enhancements)"
echo "- was-node-suite-comfyui (additional utility nodes)"
echo "- rgthree-comfy (workflow organization nodes)"
