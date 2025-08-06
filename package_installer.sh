#!/bin/bash
# Package Installer for ComfyUI - GitHub repos and Python packages
echo "========================================"
echo "📦 ComfyUI Package Installer"
echo "========================================"

# Set paths
COMFYUI_PATH="/workspace/ComfyUI"
SUPPORT_SCRIPTS_PATH="/workspace/support_scripts"

# Function to handle errors
handle_error() {
    echo "❌ Error: $1"
    return 1
}

# Function to check if URL is a GitHub repository
is_github_repo() {
    local url=$1
    [[ "$url" =~ ^https?://github\.com/[^/]+/[^/]+(\.git)?$ ]] || [[ "$url" =~ ^git@github\.com:([^/]+)/([^/]+)\.git$ ]]
}

# Function to extract GitHub repo info
extract_github_info() {
    local url=$1
    local repo_name=""
    
    if [[ "$url" =~ ^https?://github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
        repo_name="${BASH_REMATCH[2]}"
    elif [[ "$url" =~ ^git@github\.com:([^/]+)/([^/]+)\.git$ ]]; then
        repo_name="${BASH_REMATCH[2]}"
    fi
    
    echo "$repo_name"
}

# Function to install GitHub repository
install_github_repo() {
    local repo_url=$1
    local target_dir=$2
    
    if ! is_github_repo "$repo_url"; then
        handle_error "Invalid GitHub repository URL: $repo_url"
        return 1
    fi
    
    local repo_name=$(extract_github_info "$repo_url")
    if [ -z "$repo_name" ]; then
        handle_error "Could not extract repository name from URL: $repo_url"
        return 1
    fi
    
    echo "📥 Installing GitHub repository: $repo_name"
    
    # Check if already installed
    if [ -d "$target_dir/.git" ]; then
        echo "✅ Repository already exists, updating..."
        cd "$target_dir"
        git pull
        if [ -f "requirements.txt" ]; then
            echo "📦 Installing/updating requirements..."
            cd "$COMFYUI_PATH"
            source .venv/bin/activate
            uv pip install -r "$target_dir/requirements.txt"
            deactivate
        fi
    else
        # Clone the repository
        echo "Cloning repository..."
        if ! git clone "$repo_url" "$target_dir"; then
            handle_error "Failed to clone repository: $repo_url"
            return 1
        fi
        
        # Install requirements if exists
        if [ -f "$target_dir/requirements.txt" ]; then
            echo "📦 Installing requirements..."
            cd "$COMFYUI_PATH"
            source .venv/bin/activate
            uv pip install -r "$target_dir/requirements.txt"
            deactivate
        fi
        
        echo "✅ Repository installed successfully: $repo_name"
    fi
}

# Function to install Python package
install_python_package() {
    local package_spec=$1
    
    echo "📦 Installing Python package: $package_spec"
    
    # Activate virtual environment
    cd "$COMFYUI_PATH"
    source .venv/bin/activate
    
    # Install the package
    if uv pip install "$package_spec"; then
        echo "✅ Python package installed successfully: $package_spec"
    else
        handle_error "Failed to install Python package: $package_spec"
        deactivate
        return 1
    fi
    
    deactivate
}

# Function to select installation type
select_installation_type() {
    echo ""
    echo "Select installation type:"
    echo "1. GitHub Repository (Custom Node)"
    echo "2. Python Package"
    echo ""
    read -p "Enter your choice (1-2): " choice
    
    case "$choice" in
        1) echo "github" ;;
        2) echo "python" ;;
        *) handle_error "Invalid choice. Please select 1 or 2." ;;
    esac
}

# Function to get package/repo URL from user
get_package_from_user() {
    local install_type=$1
    local input=""
    
    case "$install_type" in
        "github")
            echo ""
            echo "Enter GitHub repository URL"
            echo "Examples:"
            echo "  https://github.com/ltdrdata/ComfyUI-Manager.git"
            echo "  https://github.com/cubiq/ComfyUI_IPAdapter_plus"
            read -p "Repository URL: " input
            ;;
        "python")
            echo ""
            echo "Enter Python package specification"
            echo "Examples:"
            echo "  numpy"
            echo "  torch==2.1.0"
            echo "  git+https://github.com/user/repo.git"
            read -p "Package: " input
            ;;
    esac
    
    echo "$input"
}

# Main installation function
install_package() {
    local package_input="$1"
    
    # Ask for installation type
    local install_type=$(select_installation_type)
    
    # If no input was provided as argument, ask for it now
    if [ -z "$package_input" ]; then
        package_input=$(get_package_from_user "$install_type")
        
        # Verify that input was provided
        if [ -z "$package_input" ]; then
            handle_error "No package/repository specified. Installation cancelled."
            return 1
        fi
    fi
    
    # Install based on type
    case "$install_type" in
        "github")
            local repo_name=$(extract_github_info "$package_input")
            local target_dir="$COMFYUI_PATH/custom_nodes/$repo_name"
            mkdir -p "$COMFYUI_PATH/custom_nodes"
            install_github_repo "$package_input" "$target_dir"
            ;;
        "python")
            install_python_package "$package_input"
            ;;
    esac
}

# Function to show help
show_help() {
    echo "ComfyUI Package Installer for RunPod.io"
    echo ""
    echo "Usage: $0 [package/repo_url]"
    echo ""
    echo "Examples:"
    echo "  $0                                      # Interactive mode"
    echo "  $0 https://github.com/user/repo.git     # Install GitHub repo"
    echo "  $0 numpy==1.21.0                        # Install Python package"
    echo ""
    echo "Supported installation types:"
    echo "  - GitHub repositories (for custom nodes)"
    echo "  - Python packages (pip installable)"
    echo ""
    echo "GitHub repositories will be installed to:"
    echo "  /workspace/ComfyUI/custom_nodes/"
    echo ""
    echo "Python packages will be installed to:"
    echo "  /workspace/ComfyUI/.venv/"
}

# Main script logic
case "${1:-help}" in
    help|--help|-h)
        show_help
        ;;
    *)
        install_package "$1"
        ;;
esac