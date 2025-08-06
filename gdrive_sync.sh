#!/bin/bash
# Google Drive Sync Tool for ComfyUI
echo "========================================"
echo "🔄 ComfyUI Google Drive Sync Tool"
echo "========================================"

# Set paths
MODELS_PATH="/workspace/comfyui_models"
SUPPORT_SCRIPTS_PATH="/workspace/support_scripts"

# Function to handle errors
handle_error() {
    echo "❌ Error: $1"
    return 1
}

# Function to install gdrive CLI if not present
install_gdrive_cli() {
    if ! command -v gdrive &>/dev/null; then
        echo "📦 Installing gdrive CLI..."
        
        # Download gdrive
        if ! wget -q -O /tmp/gdrive "https://drive.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA&export=download"; then
            handle_error "Failed to download gdrive CLI"
            return 1
        fi
        
        # Install gdrive
        chmod +x /tmp/gdrive
        sudo mv /tmp/gdrive /usr/local/bin/gdrive
        
        echo "✅ gdrive CLI installed successfully"
    else
        echo "✅ gdrive CLI already installed"
    fi
}

# Function to authenticate with Google Drive
authenticate_gdrive() {
    echo "🔐 Authenticating with Google Drive..."
    
    # Check if already authenticated
    if gdrive list | grep -q "My Drive"; then
        echo "✅ Already authenticated with Google Drive"
        return 0
    fi
    
    echo "Please follow these steps to authenticate:"
    echo "1. Run: gdrive about"
    echo "2. Copy the verification URL"
    echo "3. Open it in your browser"
    echo "4. Grant permissions"
    echo "5. Copy the verification code"
    echo "6. Paste it back in the terminal"
    echo ""
    
    read -p "Press Enter to continue with authentication..."
    
    if gdrive about; then
        echo "✅ Authentication successful"
    else
        handle_error "Authentication failed"
        return 1
    fi
}

# Function to select sync direction
select_sync_direction() {
    echo ""
    echo "Select sync direction:"
    echo "1. Upload local to Google Drive"
    echo "2. Download from Google Drive to local"
    echo "3. Bidirectional sync"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case "$choice" in
        1) echo "upload" ;;
        2) echo "download" ;;
        3) echo "bidirectional" ;;
        *) handle_error "Invalid choice. Please select 1, 2, or 3." ;;
    esac
}

# Function to select folders to sync
select_folders_to_sync() {
    echo ""
    echo "Available folders in $MODELS_PATH:"
    local folders=()
    local i=1
    
    for folder in "$MODELS_PATH"/*; do
        if [ -d "$folder" ]; then
            local folder_name=$(basename "$folder")
            folders+=("$folder_name")
            echo "$i. $folder_name"
            ((i++))
        fi
    done
    
    echo ""
    echo "Enter folder numbers to sync (comma-separated, or 'all'):"
    read -p "Your selection: " selection
    
    local selected_folders=()
    
    if [[ "$selection" == "all" ]]; then
        selected_folders=("${folders[@]}")
    else
        IFS=',' read -ra indices <<< "$selection"
        for index in "${indices[@]}"; do
            if [[ "$index" =~ ^[0-9]+$ ]]; then
                local idx=$((index - 1))
                if [ $idx -ge 0 ] && [ $idx -lt ${#folders[@]} ]; then
                    selected_folders+=("${folders[$idx]}")
                fi
            fi
        done
    fi
    
    echo "${selected_folders[@]}"
}

# Function to get Google Drive folder ID
get_gdrive_folder_id() {
    local folder_name=$1
    local parent_id=$2
    
    # Try to find existing folder
    local folder_id=$(gdrive list --query "name = '$folder_name' and trashed = false" --parent "$parent_id" | awk 'NR==2 {print $1}')
    
    if [ -n "$folder_id" ]; then
        echo "$folder_id"
    else
        # Create new folder
        folder_id=$(gdrive mkdir --parent "$parent_id" "$folder_name" | awk '{print $2}')
        echo "$folder_id"
    fi
}

# Function to upload folder to Google Drive
upload_folder() {
    local local_folder=$1
    local gdrive_parent_id=$2
    
    echo "📤 Uploading folder: $local_folder"
    
    # Get or create Google Drive folder
    local folder_name=$(basename "$local_folder")
    local gdrive_folder_id=$(get_gdrive_folder_id "$folder_name" "$gdrive_parent_id")
    
    # Upload files
    find "$local_folder" -type f | while read -r file; do
        local relative_path=${file#$local_folder/}
        local dir_path=$(dirname "$relative_path")
        
        # Create directory structure in Google Drive
        local current_parent_id="$gdrive_folder_id"
        if [ "$dir_path" != "." ]; then
            IFS='/' read -ra dirs <<< "$dir_path"
            for dir in "${dirs[@]}"; do
                current_parent_id=$(get_gdrive_folder_id "$dir" "$current_parent_id")
            done
        fi
        
        # Check if file already exists
        local file_name=$(basename "$file")
        local existing_file_id=$(gdrive list --query "name = '$file_name' and trashed = false" --parent "$current_parent_id" | awk 'NR==2 {print $1}')
        
        if [ -n "$existing_file_id" ]; then
            echo "Updating existing file: $relative_path"
            gdrive update "$existing_file_id" "$file"
        else
            echo "Uploading new file: $relative_path"
            gdrive upload --parent "$current_parent_id" "$file"
        fi
    done
    
    echo "✅ Upload completed for: $local_folder"
}

# Function to download folder from Google Drive
download_folder() {
    local gdrive_folder_id=$1
    local local_parent_folder=$2
    
    echo "📥 Downloading folder to: $local_parent_folder"
    
    # Create local folder if it doesn't exist
    mkdir -p "$local_parent_folder"
    
    # List files in Google Drive folder
    gdrive list --query "trashed = false" --parent "$gdrive_folder_id" | tail -n +2 | while read -r line; do
        local file_id=$(echo "$line" | awk '{print $1}')
        local file_name=$(echo "$line" | awk '{for(i=2;i<=NF-2;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
        local file_type=$(echo "$line" | awk '{print $(NF-1)}')
        
        if [ "$file_type" == "dir" ]; then
            # Recursively download subdirectory
            local subfolder="$local_parent_folder/$file_name"
            mkdir -p "$subfolder"
            download_folder "$file_id" "$subfolder"
        else
            # Download file
            local local_file="$local_parent_folder/$file_name"
            if [ -f "$local_file" ]; then
                echo "Skipping existing file: $file_name"
            else
                echo "Downloading file: $file_name"
                gdrive download --path "$local_parent_folder" "$file_id"
            fi
        fi
    done
    
    echo "✅ Download completed for: $local_parent_folder"
}

# Function to perform bidirectional sync
bidirectional_sync() {
    local local_folder=$1
    local gdrive_folder_id=$2
    
    echo "🔄 Performing bidirectional sync for: $local_folder"
    
    # Upload local changes to Google Drive
    upload_folder "$local_folder" "$gdrive_folder_id"
    
    # Download new files from Google Drive
    download_folder "$gdrive_folder_id" "$local_folder"
    
    echo "✅ Bidirectional sync completed for: $local_folder"
}

# Main sync function
sync_folders() {
    # Install gdrive CLI
    install_gdrive_cli
    
    # Authenticate
    authenticate_gdrive
    
    # Get root folder ID
    local root_folder_id=$(gdrive list --query "name = 'ComfyUI_Models' and trashed = false" | awk 'NR==2 {print $1}')
    if [ -z "$root_folder_id" ]; then
        root_folder_id=$(gdrive mkdir "ComfyUI_Models" | awk '{print $2}')
    fi
    
    # Select sync direction
    local sync_direction=$(select_sync_direction)
    
    # Select folders to sync
    local folders_to_sync=($(select_folders_to_sync))
    
    if [ ${#folders_to_sync[@]} -eq 0 ]; then
        handle_error "No folders selected for sync"
        return 1
    fi
    
    echo ""
    echo "Syncing folders: ${folders_to_sync[*]}"
    
    # Perform sync for each selected folder
    for folder in "${folders_to_sync[@]}"; do
        local local_folder="$MODELS_PATH/$folder"
        
        if [ ! -d "$local_folder" ]; then
            echo "⚠️  Local folder does not exist: $local_folder"
            continue
        fi
        
        case "$sync_direction" in
            "upload")
                upload_folder "$local_folder" "$root_folder_id"
                ;;
            "download")
                download_folder "$root_folder_id" "$local_folder"
                ;;
            "bidirectional")
                bidirectional_sync "$local_folder" "$root_folder_id"
                ;;
        esac
    done
    
    echo ""
    echo "✅ Sync operation completed successfully!"
}

# Function to show help
show_help() {
    echo "ComfyUI Google Drive Sync Tool for RunPod.io"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This tool allows you to sync your ComfyUI models folder with Google Drive."
    echo ""
    echo "Features:"
    echo "  - Upload local models to Google Drive"
    echo "  - Download models from Google Drive"
    echo "  - Bidirectional sync"
    echo "  - Selective folder syncing"
    echo ""
    echo "Requirements:"
    echo "  - Google account"
    echo "  - Internet connection"
    echo ""
    echo "Note: First run will require authentication with Google Drive."
}

# Main script logic
case "${1:-sync}" in
    help|--help|-h)
        show_help
        ;;
    sync)
        sync_folders
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac