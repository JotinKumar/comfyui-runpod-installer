#!/bin/bash
# Unified Download Manager for ComfyUI on RunPod.io
echo "========================================"
echo "📥 ComfyUI Download Manager"
echo "========================================"

# Set paths
COMFYUI_PATH="/workspace/ComfyUI"
MODELS_PATH="/workspace/comfyui_models"
SUPPORT_SCRIPTS_PATH="/workspace/support_scripts"

# Function to handle errors
handle_error() {
    echo "❌ Error: $1"
    return 1
}

# Function to select download source
select_download_source() {
    echo ""
    echo "Select download source:"
    echo "1. Civitai"
    echo "2. HuggingFace"
    echo "3. Google Drive"
    echo "4. Other (Direct URL)"
    echo ""
    read -p "Enter your choice (1-4): " source_choice
    
    case "$source_choice" in
        1) echo "civitai" ;;
        2) echo "huggingface" ;;
        3) echo "gdrive" ;;
        4) echo "other" ;;
        *) handle_error "Invalid choice. Please select 1-4." ;;
    esac
}

# Function to select target folder
select_target_folder() {
    echo ""
    echo "Available target folders:"
    echo "1. checkpoints"
    echo "2. loras"
    echo "3. vae"
    echo "4. clip"
    echo "5. unet"
    echo "6. controlnet"
    echo "7. upscale_models"
    echo "8. embeddings"
    echo "9. ipadapter"
    echo "10. animatediff_models"
    echo "11. ultralytics_bbox"
    echo "12. ultralytics_segm"
    echo "13. sams"
    echo "14. mmdets"
    echo "15. insightface"
    echo "16. pulid"
    echo ""
    read -p "Enter folder number or name (default: checkpoints): " folder_input
    
    case "$folder_input" in
        1|"checkpoints") echo "checkpoints" ;;
        2|"loras") echo "loras" ;;
        3|"vae") echo "vae" ;;
        4|"clip") echo "clip" ;;
        5|"unet") echo "unet" ;;
        6|"controlnet") echo "controlnet" ;;
        7|"upscale_models") echo "upscale_models" ;;
        8|"embeddings") echo "embeddings" ;;
        9|"ipadapter") echo "ipadapter" ;;
        10|"animatediff_models") echo "animatediff_models" ;;
        11|"ultralytics_bbox") echo "ultralytics_bbox" ;;
        12|"ultralytics_segm") echo "ultralytics_segm" ;;
        13|"sams") echo "sams" ;;
        14|"mmdets") echo "mmdets" ;;
        15|"insightface") echo "insightface" ;;
        16|"pulid") echo "pulid" ;;
        "") echo "checkpoints" ;;
        *) handle_error "Invalid folder selection. Using 'checkpoints' as default."; echo "checkpoints" ;;
    esac
}

# Function to get URL/URI from user
get_url_from_user() {
    local source_type=$1
    local url=""
    
    case "$source_type" in
        "civitai")
            echo ""
            echo "Enter Civitai model ID or URN"
            echo "Examples:"
            echo "  133005"
            echo "  urn:air:sdxl:checkpoint:civitai:133005@1759168"
            read -p "Model ID/URN: " url
            ;;
        "huggingface")
            echo ""
            echo "Enter HuggingFace model URL or repository path"
            echo "Examples:"
            echo "  https://huggingface.co/stabilityai/sdxl-vae"
            echo "  stabilityai/sdxl-vae"
            read -p "URL/Path: " url
            ;;
        "gdrive")
            echo ""
            echo "Enter Google Drive file or folder URL"
            echo "Example: https://drive.google.com/file/d/1ABCxyz123/view"
            read -p "URL: " url
            ;;
        "other")
            echo ""
            echo "Enter direct download URL"
            echo "Example: https://example.com/model.safetensors"
            read -p "URL: " url
            ;;
    esac
    
    echo "$url"
}

# Function to download from Civitai
download_from_civitai() {
    local model_id=$1
    local target_dir=$2
    
    # Check if Python is available
    if ! command -v python3 &>/dev/null; then
        handle_error "Python3 not found. Cannot download from Civitai."
        return 1
    fi
    
    # Create Civitai download script if not exists
    if [ ! -f "$SUPPORT_SCRIPTS_PATH/download_civitai.py" ]; then
        mkdir -p "$SUPPORT_SCRIPTS_PATH"
        cat > "$SUPPORT_SCRIPTS_PATH/download_civitai.py" << 'PYTHON_EOF'
import os
import re
import requests
import argparse
from tqdm import tqdm
import getpass

def setup_api_key():
    """Check for API key and prompt if missing"""
    api_key = os.getenv("CIVITAI_API_KEY")
    
    if not api_key:
        print("Civitai API key not found in environment variables")
        api_key = getpass.getpass("Enter your Civitai API key (input will be hidden): ")
        
        if not api_key or len(api_key) < 20:
            raise ValueError("Invalid API key format. Please check your key and try again.")
        
        os.environ["CIVITAI_API_KEY"] = api_key
        print("API key stored in environment variable for this session")
        
        save_permanently = input("Save API key permanently? (y/n): ").lower().strip()
        if save_permanently == 'y':
            save_to_bashrc(api_key)
            print("API key saved to ~/.bashrc for future sessions")
    
    return api_key

def save_to_bashrc(api_key):
    """Save API key to ~/.bashrc for permanent storage"""
    bashrc_path = os.path.expanduser("~/.bashrc")
    export_line = f'\nexport CIVITAI_API_KEY="{api_key}"\n'
    
    if os.path.exists(bashrc_path):
        with open(bashrc_path, 'r') as f:
            content = f.read()
            if "CIVITAI_API_KEY" in content:
                print("API key already exists in ~/.bashrc")
                return
    
    with open(bashrc_path, 'a') as f:
        f.write(export_line)

def parse_urn(urn):
    """Parse Civitai URN format to extract model and version IDs"""
    pattern = r'^urn:air:[^:]+:[^:]+:civitai:(\d+)@(\d+)$'
    match = re.match(pattern, urn)
    if match:
        return match.group(1), match.group(2)
    return None, None

def download_model(model_identifier, output_dir="."):
    api_key = setup_api_key()
    
    model_id, version_id = parse_urn(model_identifier)
    
    if not model_id:
        model_id = model_identifier
        version_id = None

    headers = {"Authorization": f"Bearer {api_key}"}
    
    model_url = f"https://civitai.com/api/v1/models/{model_id}"
    print(f"Fetching model info for ID: {model_id}")
    response = requests.get(model_url, headers=headers)
    response.raise_for_status()
    model_data = response.json()

    versions = model_data.get("modelVersions", [])
    if not versions:
        raise ValueError("No model versions found")

    target_version = None
    if version_id:
        for version in versions:
            if str(version["id"]) == version_id:
                target_version = version
                break
        if not target_version:
            raise ValueError(f"Version {version_id} not found for model {model_id}")
    else:
        target_version = versions[0]
        version_id = target_version["id"]

    print(f"Using version {version_id}: {target_version['name']}")

    files = target_version.get("files", [])
    if not files:
        raise ValueError("No downloadable files found")

    for file in files:
        download_url = file.get("downloadUrl")
        filename = file.get("name", f"model_{model_id}_v{version_id}")
        filepath = os.path.join(output_dir, filename)
        
        print(f"\nDownloading: {filename}")
        print(f"Size: {file.get('sizeKB', 0)/1024:.2f} MB")
        
        with requests.get(download_url, headers=headers, stream=True) as r:
            r.raise_for_status()
            total_size = int(r.headers.get('content-length', 0))
            
            with open(filepath, 'wb') as f, tqdm(
                unit='B',
                unit_scale=True,
                unit_divisor=1024,
                miniters=1,
                desc=filename,
                total=total_size
            ) as progress:
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        progress.update(len(chunk))
        
        print(f"Saved to: {filepath}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download Civitai models using URN or model ID")
    parser.add_argument("model_identifier", help="Civitai model ID or URN")
    parser.add_argument("--output-dir", default=".", help="Output directory")
    
    args = parser.parse_args()
    download_model(args.model_identifier, args.output_dir)
PYTHON_EOF
        chmod +x "$SUPPORT_SCRIPTS_PATH/download_civitai.py"
    fi
    
    # Activate virtual environment and run download
    cd "$COMFYUI_PATH"
    source .venv/bin/activate
    uv pip install --quiet tqdm requests
    
    python "$SUPPORT_SCRIPTS_PATH/download_civitai.py" "$model_id" --output-dir "$target_dir"
    deactivate
}

# Function to download from HuggingFace
download_from_huggingface() {
    local url=$1
    local target_dir=$2
    
    # Check if Python is available
    if ! command -v python3 &>/dev/null; then
        handle_error "Python3 not found. Cannot download from HuggingFace."
        return 1
    fi
    
    # Create HuggingFace download script if not exists
    if [ ! -f "$SUPPORT_SCRIPTS_PATH/download_huggingface.py" ]; then
        mkdir -p "$SUPPORT_SCRIPTS_PATH"
        cat > "$SUPPORT_SCRIPTS_PATH/download_huggingface.py" << 'PYTHON_EOF'
import os
import re
import argparse
import requests
from urllib.parse import urlparse, parse_qs
from pathlib import Path

def is_valid_url(url):
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except:
        return False

def extract_repo_info(url):
    parsed = urlparse(url)
    path_parts = parsed.path.strip('/').split('/')
    
    repo_type = "model"
    if path_parts and path_parts[0] in ["datasets", "spaces"]:
        repo_type = path_parts[0]
        path_parts = path_parts[1:]
    
    if len(path_parts) < 1:
        raise ValueError("Invalid repository URL")
    
    repo_id = "/".join(path_parts)
    return repo_id, repo_type

def get_repo_files(repo_id, repo_type="model"):
    api_url = f"https://huggingface.co/api/{repo_type}s/{repo_id}/tree/main"
    
    try:
        response = requests.get(api_url)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching repository files: {e}")
        return None

def download_file(url, output_dir="."):
    clean_url = url.split('?')[0]
    parsed = urlparse(clean_url)
    filename = os.path.basename(parsed.path)
    
    if not filename:
        print("Could not determine filename from URL")
        return
    
    output_path = os.path.join(output_dir, filename)
    
    try:
        print(f"Downloading {filename}...")
        with requests.get(url, stream=True) as r:
            r.raise_for_status()
            total_size = int(r.headers.get('content-length', 0))
            
            with open(output_path, 'wb') as f:
                if total_size > 0:
                    dl = 0
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            dl += len(chunk)
                            done = int(50 * dl / total_size)
                            print(f"\r[{'=' * done}{' ' * (50-done)}] {dl/total_size:.1%}", end='')
                    print()
                else:
                    f.write(r.content)
        
        print(f"File saved to: {output_path}")
    except Exception as e:
        print(f"Error downloading file: {e}")

def download_from_repo(repo_id, repo_type, output_dir="."):
    files = get_repo_files(repo_id, repo_type)
    if not files:
        print("No files found or error occurred")
        return
    
    print(f"\nFiles in {repo_id} ({repo_type}):")
    for i, file_info in enumerate(files):
        print(f"{i+1}. {file_info['path']} ({file_info.get('size', 0)/1024/1024:.2f} MB)")
    
    try:
        selection = input("\nEnter file numbers to download (comma-separated, or 'all'): ").strip()
        
        if selection.lower() == 'all':
            selected_files = files
        else:
            indices = [int(x.strip()) - 1 for x in selection.split(',')]
            selected_files = [files[i] for i in indices if 0 <= i < len(files)]
        
        if not selected_files:
            print("No valid files selected")
            return
        
        os.makedirs(output_dir, exist_ok=True)
        
        for file_info in selected_files:
            file_path = file_info['path']
            download_url = f"https://huggingface.co/{repo_type}s/{repo_id}/resolve/main/{file_path}"
            download_file(download_url, output_dir)
            
    except (ValueError, IndexError):
        print("Invalid selection. Please enter valid numbers separated by commas.")
    except KeyboardInterrupt:
        print("\nDownload cancelled by user")

def main():
    parser = argparse.ArgumentParser(description="Download files from Hugging Face Hub")
    parser.add_argument("url", help="Hugging Face URL (file or repository)")
    parser.add_argument("--output-dir", default=".", help="Output directory")
    
    args = parser.parse_args()
    
    if not is_valid_url(args.url):
        print("Invalid URL provided")
        return
    
    if "/resolve/" in args.url:
        download_file(args.url, args.output_dir)
    else:
        try:
            repo_id, repo_type = extract_repo_info(args.url)
            download_from_repo(repo_id, repo_type, args.output_dir)
        except ValueError as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()
PYTHON_EOF
        chmod +x "$SUPPORT_SCRIPTS_PATH/download_huggingface.py"
    fi
    
    # Activate virtual environment and run download
    cd "$COMFYUI_PATH"
    source .venv/bin/activate
    uv pip install --quiet tqdm requests
    
    python "$SUPPORT_SCRIPTS_PATH/download_huggingface.py" "$url" --output-dir "$target_dir"
    deactivate
}

# Function to download from Google Drive
download_from_gdrive() {
    local url=$1
    local target_dir=$2
    
    # Check if Python is available
    if ! command -v python3 &>/dev/null; then
        handle_error "Python3 not found. Cannot download from Google Drive."
        return 1
    fi
    
    # Create Google Drive download script if not exists
    if [ ! -f "$SUPPORT_SCRIPTS_PATH/download_gdrive.py" ]; then
        mkdir -p "$SUPPORT_SCRIPTS_PATH"
        cat > "$SUPPORT_SCRIPTS_PATH/download_gdrive.py" << 'PYTHON_EOF'
import os
import re
import argparse
import requests
import shutil
import tempfile
from urllib.parse import urlparse, parse_qs
from pathlib import Path

def install_gdown():
    try:
        import gdown
    except ImportError:
        print("Installing gdown...")
        import subprocess
        subprocess.check_call(["pip", "install", "gdown"])
        import gdown
    return gdown

def is_google_drive_url(url):
    parsed = urlparse(url)
    return parsed.netloc in ["drive.google.com", "docs.google.com"]

def extract_file_id(url):
    patterns = [
        r"/file/d/([a-zA-Z0-9_-]+)",
        r"id=([a-zA-Z0-9_-]+)",
        r"/open\?id=([a-zA-Z0-9_-]+)"
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None

def extract_folder_id(url):
    patterns = [
        r"/folders/([a-zA-Z0-9_-]+)",
        r"folderid=([a-zA-Z0-9_-]+)"
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None

def download_file(url, output_dir="."):
    gdown = install_gdown()
    
    file_id = extract_file_id(url)
    if not file_id:
        print("Could not extract file ID from URL")
        return
    
    try:
        print(f"Downloading file with ID: {file_id}")
        output = gdown.download(id=file_id, output=output_dir, quiet=False)
        if output:
            print(f"File downloaded to: {output}")
        else:
            print("Download failed")
    except Exception as e:
        print(f"Error downloading file: {e}")

def list_folder_contents(folder_id):
    gdown = install_gdown()
    
    try:
        with tempfile.TemporaryDirectory() as temp_dir:
            print("Fetching folder contents...")
            gdown.download_folder(id=folder_id, output=temp_dir, quiet=True)
            
            files = []
            for root, _, filenames in os.walk(temp_dir):
                for filename in filenames:
                    file_path = os.path.join(root, filename)
                    rel_path = os.path.relpath(file_path, temp_dir)
                    file_size = os.path.getsize(file_path) / (1024 * 1024)
                    files.append({
                        "path": rel_path,
                        "size": file_size,
                        "id": None
                    })
            
            return files
    except Exception as e:
        print(f"Error listing folder contents: {e}")
        return []

def download_folder(url, output_dir="."):
    folder_id = extract_folder_id(url)
    if not folder_id:
        print("Could not extract folder ID from URL")
        return
    
    files = list_folder_contents(folder_id)
    if not files:
        print("No files found in the folder")
        return
    
    print(f"\nFound {len(files)} files in the folder:")
    for i, file_info in enumerate(files):
        print(f"{i+1}. {file_info['path']} ({file_info['size']:.2f} MB)")
    
    try:
        selection = input("\nEnter file numbers to download (comma-separated, or 'all'): ").strip()
        
        if selection.lower() == 'all':
            selected_files = files
        else:
            indices = [int(x.strip()) - 1 for x in selection.split(',')]
            selected_files = [files[i] for i in indices if 0 <= i < len(files)]
        
        if not selected_files:
            print("No valid files selected")
            return
        
        gdown = install_gdown()
        with tempfile.TemporaryDirectory() as temp_dir:
            print(f"\nDownloading folder to temporary location...")
            gdown.download_folder(id=folder_id, output=temp_dir, quiet=False)
            
            os.makedirs(output_dir, exist_ok=True)
            for file_info in selected_files:
                src_path = os.path.join(temp_dir, file_info['path'])
                dst_path = os.path.join(output_dir, file_info['path'])
                
                os.makedirs(os.path.dirname(dst_path), exist_ok=True)
                
                print(f"Copying {file_info['path']}...")
                shutil.copy2(src_path, dst_path)
                print(f"Saved to: {dst_path}")
                
    except (ValueError, IndexError):
        print("Invalid selection. Please enter valid numbers separated by commas.")
    except KeyboardInterrupt:
        print("\nDownload cancelled by user")

def main():
    parser = argparse.ArgumentParser(description="Download files from Google Drive")
    parser.add_argument("url", help="Google Drive URL (file or folder)")
    parser.add_argument("--output-dir", default=".", help="Output directory")
    
    args = parser.parse_args()
    
    if not is_google_drive_url(args.url):
        print("Invalid Google Drive URL provided")
        return
    
    if "/file/d/" in args.url or "id=" in args.url:
        download_file(args.url, args.output_dir)
    elif "/folders/" in args.url or "folderid=" in args.url:
        download_folder(args.url, args.output_dir)
    else:
        print("Unrecognized Google Drive URL format")

if __name__ == "__main__":
    main()
PYTHON_EOF
        chmod +x "$SUPPORT_SCRIPTS_PATH/download_gdrive.py"
    fi
    
    # Activate virtual environment and run download
    cd "$COMFYUI_PATH"
    source .venv/bin/activate
    uv pip install --quiet tqdm requests gdown
    
    python "$SUPPORT_SCRIPTS_PATH/download_gdrive.py" "$url" --output-dir "$target_dir"
    deactivate
}

# Function to download from other sources
download_from_other() {
    local url=$1
    local target_dir=$2
    
    echo "Downloading to $target_dir..."
    cd "$target_dir"
    
    # Extract filename from URL and remove query parameters
    local filename=$(basename "$url" | cut -d'?' -f1)
    
    # Download with resume capability
    if wget --continue --no-check-certificate -O "$filename" "$url"; then
        echo "✅ Downloaded: $filename"
        
        # Ask if user wants to rename the file
        read -p "Do you want to rename the file? (Y/n): " rename_choice
        case "$rename_choice" in
            [nN][oO]|[nN])
                echo "File kept as: $filename"
                ;;
            *)
                read -p "Please enter the new file name: " new_filename
                if [ -n "$new_filename" ]; then
                    mv "$filename" "$new_filename"
                    echo "✅ File renamed to: $new_filename"
                else
                    echo "No rename performed. File kept as: $filename"
                fi
                ;;
        esac
    else
        handle_error "Failed to download: $url"
        return 1
    fi
}

# Main download function
download_model() {
    local model_url="$1"
    
    # Ask for source type
    local source_type=$(select_download_source)
    
    # If no URL was provided as argument, ask for it now
    if [ -z "$model_url" ]; then
        model_url=$(get_url_from_user "$source_type")
        
        # Verify that URL was provided
        if [ -z "$model_url" ]; then
            handle_error "No model URL or ID provided. Download cancelled."
            return 1
        fi
    fi
    
    # Select target folder
    local folder=$(select_target_folder)
    local target_path="$MODELS_PATH/$folder"
    
    # Create directory if it doesn't exist
    mkdir -p "$target_path"
    
    # Download based on source type
    case "$source_type" in
        "civitai")
            download_from_civitai "$model_url" "$target_path"
            ;;
        "huggingface")
            download_from_huggingface "$model_url" "$target_path"
            ;;
        "gdrive")
            download_from_gdrive "$model_url" "$target_path"
            ;;
        "other")
            download_from_other "$model_url" "$target_path"
            ;;
    esac
}

# Function to show help
show_help() {
    echo "ComfyUI Download Manager for RunPod.io"
    echo ""
    echo "Usage: $0 [url]"
    echo ""
    echo "Examples:"
    echo "  $0                          # Interactive mode"
    echo "  $0 <url>                   # Download with specific URL"
    echo "  $0 <model_id>              # Download Civitai model by ID"
    echo ""
    echo "Supported sources:"
    echo "  - Civitai (model ID or URN)"
    echo "  - HuggingFace (repository or file URL)"
    echo "  - Google Drive (file or folder URL)"
    echo "  - Direct download URLs"
    echo ""
    echo "Target folders:"
    echo "  checkpoints, loras, vae, clip, unet, controlnet, upscale_models"
    echo "  embeddings, ipadapter, animatediff_models, ultralytics_bbox"
    echo "  ultralytics_segm, sams, mmdets, insightface, pulid"
}

# Main script logic
case "${1:-help}" in
    help|--help|-h)
        show_help
        ;;
    *)
        download_model "$1"
        ;;
esac