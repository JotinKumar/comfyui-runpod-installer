#!/bin/bash
# Optional Custom Nodes Installer for ComfyUI on RunPod.io
echo "========================================"
echo "🔌 Optional Custom Nodes Installer"
echo "========================================"

# Set paths
COMFYUI_PATH="/workspace/ComfyUI"

# Function to handle errors
handle_error() {
    echo "❌ Error: $1"
    return 1
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
            # Activate virtual environment and install requirements
            cd "$COMFYUI_PATH"
            source .venv/bin/activate
            if ! uv pip install -r "${target_dir}/requirements.txt"; then
                echo "⚠️  Failed to install ${node_name} requirements, continuing..."
            fi
            deactivate
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
            cd "$COMFYUI_PATH"
            source .venv/bin/activate
            if ! uv pip install -r "${target_dir}/requirements.txt"; then
                echo "⚠️  Failed to update ${node_name} requirements, continuing..."
            fi
            deactivate
        fi
        cd "$COMFYUI_PATH" || handle_error "Failed to return to ComfyUI directory"
    fi
    return 0
}

# Function to display and select optional custom nodes
select_and_install_nodes() {
    echo ""
    echo "Available Optional Custom Nodes:"
    echo "----------------------------------------"
    
    # Define optional custom nodes with descriptions
    declare -A OPTIONAL_NODES=(
        ["1"]="ComfyUI_IPAdapter_plus|https://github.com/cubiq/ComfyUI_IPAdapter_plus.git|IP Adapter for image prompting and style transfer"
        ["2"]="comfyui_controlnet_aux|https://github.com/Fannovel16/comfyui_controlnet_aux.git|ControlNet auxiliary preprocessors (Canny, Depth, Pose, etc.)"
        ["3"]="ComfyUI-AnimateDiff-Evolved|https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git|AnimateDiff for video generation and animation"
        ["4"]="ComfyUI-Custom-Scripts|https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git|Collection of useful custom scripts and utilities"
        ["5"]="rgthree-comfy|https://github.com/rgthree/rgthree-comfy.git|rgthree's custom nodes for advanced workflows"
        ["6"]="ComfyUI-segment-anything|https://github.com/continue-revolution/ComfyUI-segment-anything.git|Segment Anything Model (SAM) integration"
        ["7"]="ComfyUI-Swin2SR|https://github.com/blaise-tk/ComfyUI_Swin2SR.git|Super-resolution with Swin2SR models"
        ["8"]="ComfyUI-PuLID|https://github.com/cubiq/ComfyUI-PuLID.git|PuLID for ID preservation in portrait generation"
        ["9"]="ComfyUI-InstantID|https://github.com/cubiq/ComfyUI-InstantID.git|InstantID for instant identity preservation"
        ["10"]="ComfyUI-LCM|https://github.com/0xbitches/ComfyUI-LCM-Lora|Latent Consistency Models for fast generation"
        ["11"]="ComfyUI-VideoHelperSuite|https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git|Video processing utilities for ComfyUI"
        ["12"]="ComfyUI-Advanced-ControlNet|https://github.com/EmptyNeuron/ComfyUI-Advanced-ControlNet.git|Advanced ControlNet nodes and features"
        ["13"]="ComfyUI-ExLLaVA|https://github.com/xinyu1205/ComfyUI-ExLLaVA.git|ExLLaVA for multimodal understanding"
        ["14"]="ComfyUI-3D-Pack|https://github.com/MrForExample/ComfyUI-3D-Pack.git|3D generation and processing nodes"
        ["15"]="ComfyUI-TensorRT|https://github.com/NVIDIA/ComfyUI-TensorRT.git|TensorRT acceleration for faster inference"
    )
    
    # Display the list
    for i in {1..15}; do
        if [[ -v "OPTIONAL_NODES[$i]" ]]; then
            IFS='|' read -r node_name repo_url description <<< "${OPTIONAL_NODES[$i]}"
            printf "%2d. %-30s - %s\n" "$i" "$node_name" "$description"
        fi
    done
    
    echo ""
    echo "Enter the numbers of the custom nodes you want to install (comma-separated)"
    echo "Example: 1,3,5,7"
    echo "Enter 'all' to install all optional nodes"
    echo "Enter 'none' to skip installation"
    read -p "Your selection: " selection
    
    # Process selection
    if [[ "$selection" == "none" ]]; then
        echo "⚠️  Skipping optional custom nodes installation"
        return 0
    elif [[ "$selection" == "all" ]]; then
        # Install all nodes
        echo ""
        echo "📥 Installing all optional custom nodes..."
        echo "----------------------------------------"
        
        for i in {1..15}; do
            if [[ -v "OPTIONAL_NODES[$i]" ]]; then
                IFS='|' read -r node_name repo_url description <<< "${OPTIONAL_NODES[$i]}"
                echo ""
                echo "Installing $node_name..."
                if ! install_custom_node "$repo_url" "$node_name"; then
                    echo "⚠️  Failed to install $node_name, continuing with others..."
                fi
            fi
        done
    else
        # Install selected nodes
        echo ""
        echo "📥 Installing selected optional custom nodes..."
        echo "----------------------------------------"
        
        # Parse comma-separated selection
        IFS=',' read -ra selections <<< "$selection"
        for num in "${selections[@]}"; do
            # Trim whitespace
            num=$(echo "$num" | xargs)
            
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le 15 ]]; then
                if [[ -v "OPTIONAL_NODES[$num]" ]]; then
                    IFS='|' read -r node_name repo_url description <<< "${OPTIONAL_NODES[$num]}"
                    echo ""
                    echo "Installing $node_name..."
                    if ! install_custom_node "$repo_url" "$node_name"; then
                        echo "⚠️  Failed to install $node_name, continuing with others..."
                    fi
                else
                    echo "⚠️  Invalid selection: $num (node not found)"
                fi
            else
                echo "⚠️  Invalid selection: $num (please enter numbers 1-15)"
            fi
        done
    fi
    
    echo ""
    echo "✅ Optional custom nodes installation completed!"
}

# Function to show help
show_help() {
    echo "ComfyUI Optional Custom Nodes Installer for RunPod.io"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This script allows you to install optional custom nodes for ComfyUI."
    echo ""
    echo "Features:"
    echo "  - Interactive selection of custom nodes"
    echo "  - Install multiple nodes at once"
    echo "  - Automatic dependency installation"
    echo "  - Update existing nodes"
    echo ""
    echo "Available nodes include:"
    echo "  - IP Adapter for image prompting"
    echo "  - ControlNet auxiliary preprocessors"
    echo "  - AnimateDiff for video generation"
    echo "  - Segment Anything Model (SAM)"
    echo "  - Super-resolution models"
    echo "  - ID preservation tools (PuLID, InstantID)"
    echo "  - And many more..."
    echo ""
    echo "Note: ComfyUI must be installed first before running this script."
}

# Main script logic
case "${1:-install}" in
    help|--help|-h)
        show_help
        ;;
    install)
        # Check if ComfyUI directory exists
        if [ ! -d "$COMFYUI_PATH" ]; then
            handle_error "ComfyUI not found at $COMFYUI_PATH. Please install ComfyUI first."
            exit 1
        fi
        
        # Check if virtual environment exists
        if [ ! -d "$COMFYUI_PATH/.venv" ]; then
            handle_error "Virtual environment not found. Please install ComfyUI first."
            exit 1
        fi
        
        # Start the selection and installation process
        select_and_install_nodes
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac