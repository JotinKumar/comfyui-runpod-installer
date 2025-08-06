#!/bin/bash
# ComfyUI Complete Installation Script for RunPod.io with 5090 (CUDA 12.8) Support
echo "========================================"
echo "🚀 Starting Complete ComfyUI Setup for RunPod.io..."
echo "========================================"

# Set UV_LINK_MODE to copy to avoid hardlinking issues across filesystems
export UV_LINK_MODE=copy

# Set paths
COMFYUI_PATH="/workspace/ComfyUI"
MODELS_PATH="/workspace/comfyui_models"
SUPPORT_SCRIPTS_PATH="/workspace/support_scripts"

# Function to handle errors
handle_error() {
    echo "❌ Error: $1"
    exit 1
}

# Function to check disk space
check_disk_space() {
    echo "----------------------------------------"
    echo "💾 Checking available disk space..."
    echo "----------------------------------------"
    
    local required_space=10000 # 10GB in MB
    local available_space=$(df -m /workspace | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        handle_error "Insufficient disk space. Required: ${required_space}MB, Available: ${available_space}MB"
    fi
    
    echo "✅ Sufficient disk space available: ${available_space}MB"
}

# Function to install required system packages
install_system_packages() {
    echo "----------------------------------------"
    echo "📦 Installing required system packages..."
    echo "----------------------------------------"
    
    # Update package list
    apt-get update -qq
    
    # Install required packages
    apt-get install -y -qq unzip wget git curl python3-pip || handle_error "Failed to install system packages"
    echo "✅ System packages installed successfully"
}

# Function to install uv if not present
install_uv() {
    echo "----------------------------------------"
    echo "📦 Installing uv package manager..."
    echo "----------------------------------------"
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh || handle_error "Failed to install uv"
        
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
        
        # Fallback if env file not found
        if ! command -v uv &>/dev/null; then
            echo "Warning: uv env file not found. Setting PATH manually."
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
        # Verify uv installation
        if ! command -v uv &>/dev/null; then
            handle_error "uv installation failed!"
        fi
        echo "✅ uv installed successfully"
    else
        echo "✅ uv already installed"
    fi
}

# Function to create base directories
create_base_directories() {
    echo "----------------------------------------"
    echo "📁 Creating base directories..."
    echo "----------------------------------------"
    mkdir -p "$COMFYUI_PATH" || handle_error "Failed to create ComfyUI directory"
    mkdir -p "$MODELS_PATH" || handle_error "Failed to create models directory"
    mkdir -p "$SUPPORT_SCRIPTS_PATH" || handle_error "Failed to create support scripts directory"
    echo "✅ Base directories created"
}

# Function to clone ComfyUI repository
clone_comfyui() {
    echo "----------------------------------------"
    echo "📥 Cloning or updating ComfyUI repository..."
    echo "----------------------------------------"
    if [ ! -d "$COMFYUI_PATH/.git" ]; then
        git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_PATH" || handle_error "Failed to clone ComfyUI"
        echo "✅ ComfyUI cloned successfully"
    else
        echo "✅ ComfyUI already exists, updating..."
        cd "$COMFYUI_PATH" || handle_error "Failed to navigate to ComfyUI directory"
        git pull || handle_error "Failed to update ComfyUI"
    fi
}

# Function to create virtual environment
create_venv() {
    echo "----------------------------------------"
    echo "🐍 Creating virtual environment with uv..."
    echo "----------------------------------------"
    cd "$COMFYUI_PATH" || handle_error "Failed to navigate to ComfyUI directory"
    
    if [ ! -d ".venv" ]; then
        uv venv --python 3.11 --seed || handle_error "Failed to create virtual environment"
        echo "✅ Virtual environment created with Python 3.11"
        
        # Ensure proper permissions on activation script
        chmod +x .venv/bin/activate || handle_error "Failed to set permissions on activation script"
        chmod +x .venv/bin/python || handle_error "Failed to set permissions on python executable"
    else
        echo "✅ Virtual environment already exists"
        
        # Check and fix permissions if needed
        if [ ! -x ".venv/bin/activate" ]; then
            echo "Fixing virtual environment permissions..."
            chmod +x .venv/bin/activate || handle_error "Failed to set permissions on activation script"
            chmod +x .venv/bin/python || handle_error "Failed to set permissions on python executable"
        fi
    fi
    
    # Activate virtual environment
    if [ -f ".venv/bin/activate" ]; then
        if [ ! -x ".venv/bin/activate" ]; then
            handle_error "Virtual environment activation script is not executable"
        fi
        source .venv/bin/activate || handle_error "Failed to activate virtual environment"
        echo "✅ Virtual environment activated"
    else
        handle_error "Virtual environment activation script not found"
    fi
}

# Function to install dependencies
install_dependencies() {
    echo "----------------------------------------"
    echo "📦 Upgrading pip, setuptools, wheel using uv..."
    echo "----------------------------------------"
    uv pip install --upgrade pip setuptools wheel || handle_error "Failed to upgrade pip"
    echo "✅ pip upgraded"
    
    echo "----------------------------------------"
    echo "🔥 Installing PyTorch with CUDA 12.8 for 5090 support..."
    echo "----------------------------------------"
    uv pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 || handle_error "Failed to install PyTorch"
    echo "✅ PyTorch with CUDA 12.8 installed"
    
    echo "----------------------------------------"
    echo "📦 Installing xformers..."
    echo "----------------------------------------"
    echo "⚠️  This may take several minutes."
    read -p "Do you want to skip xformers installation? (y/N): " skip_xformers
    case "$skip_xformers" in
        [yY][eE][sS]|[yY])
            echo "⚠️  Skipping xformers installation"
            ;;
        *)
            echo "Installing xformers... This may take several minutes."
            uv pip install xformers || handle_error "Failed to install xformers"
            echo "✅ xformers installed"
            ;;
    esac
    
    echo "----------------------------------------"
    echo "📦 Installing ComfyUI requirements..."
    echo "----------------------------------------"
    uv pip install -r requirements.txt || handle_error "Failed to install ComfyUI requirements"
    echo "✅ ComfyUI requirements installed"
    
    echo "----------------------------------------"
    echo "📦 Installing onnxruntime-gpu..."
    echo "----------------------------------------"
    uv pip install onnxruntime-gpu || handle_error "Failed to install onnxruntime-gpu"
    echo "✅ onnxruntime-gpu installed"
}

# Function to install custom node
install_custom_node() {
    local repo_url=$1
    local node_name=$2
    local target_dir="$COMFYUI_PATH/custom_nodes/$node_name"
    
    mkdir -p "$COMFYUI_PATH/custom_nodes"
    
    if [ ! -d "${target_dir}/.git" ]; then
        echo "📥 Installing ${node_name}..."
        
        # Try cloning with depth 1 for faster download
        if ! git clone --depth 1 "${repo_url}" "${target_dir}" 2>/dev/null; then
            echo "⚠️  Failed to clone ${node_name} with depth 1, trying full clone..."
            if ! git clone "${repo_url}" "${target_dir}"; then
                echo "❌ Failed to clone ${node_name}"
                return 1
            fi
        fi
        
        if [ -f "${target_dir}/requirements.txt" ]; then
            cd "${target_dir}" || handle_error "Failed to navigate to ${node_name}"
            echo "📦 Installing ${node_name} requirements..."
            # Ensure torch is available for build dependencies
            if ! uv pip install -r requirements.txt; then
                echo "⚠️  Failed to install ${node_name} requirements, continuing..."
            fi
            cd "$COMFYUI_PATH" || handle_error "Failed to return to ComfyUI directory"
        fi
        echo "✅ ${node_name} installed successfully"
    else
        echo "✅ ${node_name} already exists, updating..."
        cd "${target_dir}" || handle_error "Failed to navigate to ${node_name}"
        
        if ! git pull; then
            echo "⚠️  Failed to update ${node_name}, continuing..."
        fi
        
        if [ -f "requirements.txt" ]; then
            echo "📦 Updating ${node_name} requirements..."
            if ! uv pip install -r requirements.txt; then
                echo "⚠️  Failed to update ${node_name} requirements, continuing..."
            fi
        fi
        cd "$COMFYUI_PATH" || handle_error "Failed to return to ComfyUI directory"
    fi
    return 0
}

# Function to install essential custom nodes
install_essential_custom_nodes() {
    echo "----------------------------------------"
    echo "🔌 Installing essential custom nodes..."
    echo "----------------------------------------"
    
    # List of essential custom nodes
    declare -A ESSENTIAL_NODES=(
        ["ComfyUI-Manager"]="https://github.com/ltdrdata/ComfyUI-Manager.git"
        ["ComfyUI-Impact-Pack"]="https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
        ["was-node-suite-comfyui"]="https://github.com/WASasquatch/was-node-suite-comfyui.git"
        ["ComfyUI-Essentials"]="https://github.com/cubiq/ComfyUI_Essentials.git"
        ["KJNodes-for-ComfyUI"]="https://github.com/kijai/ComfyUI-KJNodes.git"
    )
    
    for node_name in "${!ESSENTIAL_NODES[@]}"; do
        repo_url="${ESSENTIAL_NODES[$node_name]}"
        echo ""
        echo "Installing $node_name..."
        if ! install_custom_node "$repo_url" "$node_name"; then
            echo "⚠️  Failed to install $node_name, but continuing with installation..."
        fi
    done
}

# Function to create model directories
create_model_directories() {
    echo "----------------------------------------"
    echo "📁 Creating model directories..."
    echo "----------------------------------------"
    
    mkdir -p "$COMFYUI_PATH"/models/{checkpoints,loras,vae,clip,unet,controlnet,upscale_models,embeddings,ipadapter,animatediff_models,ultralytics_bbox,ultralytics_segm,sams,mmdets,insightface}
    echo "✅ Model directories created"
}

# Function to setup models folder structure
setup_models_folder() {
    echo "----------------------------------------"
    echo "📁 Setting up external models folder structure..."
    echo "----------------------------------------"
    
    # Create models folder structure
    mkdir -p "$MODELS_PATH"/{checkpoints,loras,vae,clip,clip_vision,configs,controlnet,diffusion_models,unet,embeddings,hypernetworks,upscale_models,ipadapter,animatediff_models,ultralytics_bbox,ultralytics_segm,sams,mmdets,insightface,pulid}
    echo "✅ External models folder structure created"
    
    # Create extra_model_paths.yaml configuration
    if [ -f "$COMFYUI_PATH/extra_model_paths.yaml" ]; then
        cp "$COMFYUI_PATH/extra_model_paths.yaml" "$COMFYUI_PATH/extra_model_paths.yaml.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ Existing extra_model_paths.yaml backed up"
    fi
    
    cat > "$COMFYUI_PATH/extra_model_paths.yaml" << 'EOF'
# ComfyUI Extra Model Paths Configuration
comfyui_models:
  base_path: /workspace/comfyui_models/
  is_default: true
  checkpoints: checkpoints/
  clip: clip/
  clip_vision: clip_vision/
  configs: configs/
  controlnet: controlnet/
  diffusion_models: diffusion_models/
  unet: unet/
  embeddings: embeddings/
  hypernetworks: hypernetworks/
  loras: loras/
  upscale_models: upscale_models/
  vae: vae/
  ipadapter: ipadapter/
  animatediff_models: animatediff_models/
  ultralytics_bbox: ultralytics_bbox/
  ultralytics_segm: ultralytics_segm/
  sams: sams/
  mmdets: mmdets/
  insightface: insightface/
  pulid: pulid/
EOF
    echo "✅ extra_model_paths.yaml configuration created"
}

# Function to create startup script
create_startup_script() {
    echo "----------------------------------------"
    echo "📝 Creating startup script..."
    echo "----------------------------------------"
    
    cat > "$COMFYUI_PATH/start_comfyui.sh" << 'EOF'
#!/bin/bash
cd /workspace/ComfyUI
source .venv/bin/activate
python main.py --listen --port 8188
EOF
    
    chmod +x "$COMFYUI_PATH/start_comfyui.sh"
    echo "✅ Startup script created"
}

# Function to offer additional scripts installation
offer_additional_scripts() {
    echo "----------------------------------------"
    echo "🔧 Additional Functionalities Available"
    echo "----------------------------------------"
    echo ""
    echo "The following additional scripts can enhance your ComfyUI experience:"
    echo ""
    echo "📥 Download Manager Script (download_manager.sh)"
    echo "   • Unified interface for downloading models from multiple sources"
    echo "   • Supports Civitai, HuggingFace, Google Drive, and direct URLs"
    echo "   • Interactive folder selection and download management"
    echo ""
    echo "📦 Package Installer Script (package_installer.sh)"
    echo "   • Install GitHub repositories (custom nodes) automatically"
    echo "   • Install Python packages with dependency management"
    echo "   • Smart URL parsing to detect repository vs package types"
    echo ""
    echo "🔄 Google Drive Sync Script (gdrive_sync.sh)"
    echo "   • Sync your models folder with Google Drive"
    echo "   • Upload, download, or bidirectional sync options"
    echo "   • Selective folder syncing with progress tracking"
    echo ""
    echo "🔌 Optional Custom Nodes Installer (install_optional_custom_nodes.sh)"
    echo "   • Install additional custom nodes beyond the essential ones"
    echo "   • Interactive selection from 15+ popular optional nodes"
    echo "   • Includes IP Adapter, ControlNet aux, AnimateDiff, SAM, and more"
    echo ""
    echo "🛠️  Support Scripts Setup (setup_support_scripts.sh)"
    echo "   • Installs all the above scripts automatically"
    echo "   • Sets up convenient command aliases"
    echo "   • Creates quick start guide and documentation"
    echo ""
    echo "These scripts will provide you with commands like:"
    echo "  • download    - Download models from any source"
    echo "  • install     - Install packages and repositories"
    echo "  • gdrive      - Sync with Google Drive"
    echo "  • models      - Navigate to models folder"
    echo "  • comfy       - Navigate to ComfyUI folder"
    echo "  • activate    - Activate virtual environment"
    echo ""
    
    while true; do
        read -p "Do you want to download and install these additional scripts? (y/n): " install_choice
        case "$install_choice" in
            [yY][eE][sS]|[yY])
                echo ""
                echo "📥 Downloading and installing additional scripts..."
                echo "----------------------------------------"
                
                # Download and run the support scripts setup
                if wget -q --show-progress -O "/tmp/setup_support_scripts.sh" "https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/setup_support_scripts.sh"; then
                    chmod +x /tmp/setup_support_scripts.sh
                    if /tmp/setup_support_scripts.sh; then
                        echo "✅ Additional scripts installed successfully!"
                        echo ""
                        echo "🎯 Next steps:"
                        echo "1. Setup aliases: /workspace/support_scripts/setup_aliases.sh"
                        echo "2. Reload bashrc: source ~/.bashrc"
                        echo "3. View available commands: /workspace/support_scripts/quick_start.sh"
                        echo ""
                        echo "After setting up aliases, you can use:"
                        echo "  • download    - Download models"
                        echo "  • install     - Install packages/repos"
                        echo "  • gdrive      - Sync with Google Drive"
                        echo ""
                        echo "🔌 To install optional custom nodes:"
                        echo "   /workspace/support_scripts/install_optional_custom_nodes.sh"
                    else
                        echo "❌ Failed to install additional scripts"
                    fi
                    rm -f /tmp/setup_support_scripts.sh
                else
                    echo "❌ Failed to download support scripts setup"
                fi
                break
                ;;
            [nN][oO]|[nN])
                echo ""
                echo "⚠️  Skipping additional scripts installation"
                echo "You can manually install them later with:"
                echo "  wget https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/setup_support_scripts.sh"
                echo "  chmod +x setup_support_scripts.sh"
                echo "  ./setup_support_scripts.sh"
                break
                ;;
            *)
                echo "❌ Invalid choice. Please enter 'y' or 'n'."
                ;;
        esac
    done
}

# Main installation process
main() {
    # Check disk space
    check_disk_space
    
    # Install system packages
    install_system_packages
    
    # Install uv
    install_uv
    
    # Create base directories
    create_base_directories
    
    # Clone ComfyUI
    clone_comfyui
    
    # Create virtual environment
    create_venv
    
    # Install dependencies
    install_dependencies
    
    # Install essential custom nodes
    install_essential_custom_nodes
    
    # Create model directories
    create_model_directories
    
    # Setup models folder
    setup_models_folder
    
    # Create startup script
    create_startup_script
    
    # Offer additional scripts installation
    offer_additional_scripts
    
    echo ""
    echo "========================================"
    echo "✨ Core installation complete! ✨"
    echo "========================================"
    echo ""
    echo "🎯 Basic Usage:"
    echo "1. Start ComfyUI: cd /workspace/ComfyUI && ./start_comfyui.sh"
    echo "2. ComfyUI will be available at: http://localhost:8188"
    echo ""
    if [[ "$install_choice" =~ ^[yY]([eE][sS])?$ ]]; then
        echo "🚀 Enhanced Usage (after setting up aliases):"
        echo "1. Setup aliases: /workspace/support_scripts/setup_aliases.sh"
        echo "2. Reload bashrc: source ~/.bashrc"
        echo "3. Download models: download"
        echo "4. Install packages: install <package/repo>"
        echo "5. Sync with Google Drive: gdrive"
        echo "6. Start ComfyUI: comfyui"
    else
        echo "💡 To get enhanced functionality, run the support scripts setup:"
        echo "   wget https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/setup_support_scripts.sh"
        echo "   chmod +x setup_support_scripts.sh"
        echo "   ./setup_support_scripts.sh"
    fi
    echo ""
}

# Initialize install_choice variable
install_choice="n"

# Run main installation
main