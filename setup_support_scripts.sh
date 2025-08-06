#!/bin/bash
# Setup support scripts for ComfyUI on RunPod.io
echo "========================================"
echo "🔧 Setting up support scripts..."
echo "========================================"

# Set paths
SUPPORT_SCRIPTS_PATH="/workspace/support_scripts"

# Function to handle errors
handle_error() {
    echo "❌ Error: $1"
    exit 1
}

# Function to download support scripts
download_support_script() {
    local script_name=$1
    local script_url=$2
    
    echo "📥 Downloading $script_name..."
    
    if wget -q --show-progress -O "$SUPPORT_SCRIPTS_PATH/$script_name" "$script_url"; then
        chmod +x "$SUPPORT_SCRIPTS_PATH/$script_name"
        echo "✅ $script_name downloaded and made executable"
    else
        handle_error "Failed to download $script_name"
    fi
}

# Main setup process
main() {
    # Create support scripts directory
    mkdir -p "$SUPPORT_SCRIPTS_PATH"
    
    # Download support scripts
    echo "----------------------------------------"
    echo "📥 Downloading support scripts..."
    echo "----------------------------------------"
    
    download_support_script "download_manager.sh" "https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/download_manager.sh"
    download_support_script "package_installer.sh" "https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/package_installer.sh"
    download_support_script "gdrive_sync.sh" "https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/gdrive_sync.sh"
    download_support_script "install_optional_custom_nodes.sh" "https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/install_optional_custom_nodes.sh"
    
    # Create aliases script
    echo "----------------------------------------"
    echo "📝 Creating command aliases..."
    echo "----------------------------------------"
    
    cat > "$SUPPORT_SCRIPTS_PATH/setup_aliases.sh" << 'EOF'
#!/bin/bash
# Setup command aliases for ComfyUI support scripts

# Check if aliases already exist in .bashrc
if ! grep -q "ComfyUI Support Script Aliases" "$HOME/.bashrc"; then
    # Add aliases to .bashrc
    cat >> "$HOME/.bashrc" << 'BASHRC_EOF'

# ComfyUI Support Script Aliases
alias download="/workspace/support_scripts/download_manager.sh"
alias install="/workspace/support_scripts/package_installer.sh"
alias gdrive="/workspace/support_scripts/gdrive_sync.sh"
alias custom_nodes="/workspace/support_scripts/install_optional_custom_nodes.sh"
alias models="cd /workspace/comfyui_models"
alias comfy="cd /workspace/ComfyUI"
alias activate="cd /workspace/ComfyUI && source .venv/bin/activate"
BASHRC_EOF

    echo "✅ Support script aliases added to .bashrc"
    echo "To use the aliases immediately, run: source ~/.bashrc"
else
    echo "✅ Support script aliases already exist in .bashrc"
fi
EOF
    
    chmod +x "$SUPPORT_SCRIPTS_PATH/setup_aliases.sh"
    
    # Create quick start script
    cat > "$SUPPORT_SCRIPTS_PATH/quick_start.sh" << 'EOF'
#!/bin/bash
# Quick start script for ComfyUI support tools

echo "========================================"
echo "🚀 ComfyUI Support Tools Quick Start"
echo "========================================"

echo ""
echo "Available commands:"
echo ""
echo "📥 Download Manager:"
echo "  download                    # Interactive download mode"
echo "  download <url>              # Download specific URL"
echo ""
echo "📦 Package Installer:"
echo "  install                     # Interactive package installation"
echo "  install <package/repo>      # Install specific package/repo"
echo ""
echo "🔄 Google Drive Sync:"
echo "  gdrive                      # Start Google Drive sync"
echo ""
echo "🔌 Optional Custom Nodes:"
echo "  custom_nodes                # Install optional custom nodes"
echo ""
echo "📁 Navigation:"
echo "  models                      # Navigate to models folder"
echo "  comfy                       # Navigate to ComfyUI folder"
echo "  activate                    # Activate virtual environment"
echo ""
echo "Examples:"
echo "  download                    # Start interactive download"
echo "  install https://github.com/user/repo.git"
echo "  install numpy==1.21.0"
echo "  gdrive"
echo "  custom_nodes"
echo ""
echo "Note: Make sure to run 'source ~/.bashrc' after first setup"
EOF
    
    chmod +x "$SUPPORT_SCRIPTS_PATH/quick_start.sh"
    
    echo ""
    echo "========================================"
    echo "✨ Support scripts setup complete! ✨"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Setup aliases: $SUPPORT_SCRIPTS_PATH/setup_aliases.sh"
    echo "2. Reload bashrc: source ~/.bashrc"
    echo "3. View quick start: $SUPPORT_SCRIPTS_PATH/quick_start.sh"
    echo ""
    echo "Available commands after setup:"
    echo "  download    - Download models from various sources"
    echo "  install     - Install packages and repositories"
    echo "  gdrive      - Sync with Google Drive"
    echo "  custom_nodes - Install optional custom nodes"
    echo "  models      - Navigate to models folder"
    echo "  comfy       - Navigate to ComfyUI folder"
    echo "  activate    - Activate virtual environment"
}

# Run main setup
main