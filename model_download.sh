#!/bin/bash
# Script to download selected models (SDXL, Flux, HiDream)

echo "========================================"
echo "Model Download Script"
echo "========================================"

# Set paths
MODELS_PATH="/workspace/comfyui_models"
mkdir -p "$MODELS_PATH"/{checkpoints,unet}

# Model definitions
declare -A SDXL_MODELS=(
    ["SDXL Base 1.0"]="6.9GB|https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
    ["SDXL Refiner 1.0"]="3.5GB|https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors"
    ["Juggernaut XL"]="6.9GB|https://huggingface.co/RunDiffusion/Juggernaut-XL-v9/resolve/main/Juggernaut-XL-v9.safetensors"
    ["RealVis XL"]="6.9GB|https://huggingface.co/SG161222/RealVisXL_V4.0/resolve/main/RealVisXL_V4.0.safetensors"
    ["DreamShaper XL"]="6.9GB|https://huggingface.co/Lykon/DreamShaper_XL/resolve/main/DreamShaper_XL.safetensors"
    ["Animagine XL"]="6.9GB|https://huggingface.co/cagliostrolab/animagine-xl-3.1/resolve/main/animagine-xl-3.1.safetensors"
    ["ZavyChroma XL"]="6.9GB|https://huggingface.co/frankjoshua/zavychromaxl/resolve/main/zavychromaxl_v80.safetensors"
    ["SDXL Turbo"]="6.9GB|https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors"
)

declare -A FLUX_MODELS=(
    ["Flux.1-schnell"]="8GB|https://huggingface.co/Comfy-Org/flux1-schnell-fp8/resolve/main/flux1-schnell-fp8.safetensors"
    ["Flux.1-dev"]="12GB|https://huggingface.co/Comfy-Org/flux1-dev-fp8/resolve/main/flux1-dev-fp8.safetensors"
)

declare -A HIDREAM_MODELS=(
    ["HiDream-I1"]="8.5GB|https://huggingface.co/HiDream-ai/HiDream-I1/resolve/main/hidream-i1-fp8.safetensors"
    ["HiDream-E1.1"]="7GB|https://huggingface.co/HiDream-ai/HiDream-E1.1/resolve/main/hidream-e11-fp8.safetensors"
)

# Arrays to store user selections
declare -a SELECTED_SDXL=()
declare -a SELECTED_FLUX=()
declare -a SELECTED_HIDREAM=()

# Function to display model selection menu
select_models() {
    local -n models=$1
    local category=$2
    local -n selected=$3
    
    echo ""
    echo "=== $category Models ==="
    echo "Available models:"
    
    local i=1
    for model in "${!models[@]}"; do
        local size=$(echo "${models[$model]}" | cut -d'|' -f1)
        echo "$i. $model ($size)"
        ((i++))
    done
    
    echo ""
    echo "Enter the numbers of the models you want to download (comma separated):"
    echo "Example: 1,3,5"
    echo "Enter 'all' to download all models"
    echo "Enter 'none' to skip this category"
    read -p "Your selection: " selection
    
    if [[ "$selection" == "all" ]]; then
        for model in "${!models[@]}"; do
            selected+=("$model")
        done
    elif [[ "$selection" == "none" ]]; then
        echo "Skipping $category models"
    else
        IFS=',' read -ra ADDR <<< "$selection"
        for num in "${ADDR[@]}"; do
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                local index=$((num-1))
                local count=0
                for model in "${!models[@]}"; do
                    if [[ $count -eq $index ]]; then
                        selected+=("$model")
                        break
                    fi
                    ((count++))
                done
            fi
        done
    fi
}

# Function to calculate total size
calculate_size() {
    local -n selected=$1
    local -n models=$2
    local total=0
    
    for model in "${selected[@]}"; do
        local size=$(echo "${models[$model]}" | cut -d'|' -f1 | tr -d 'GB')
        total=$(echo "$total + $size" | bc)
    done
    
    echo "$total"
}

# Display SDXL selection
select_models SDXL_MODELS "SDXL" SELECTED_SDXL

# Display Flux selection
select_models FLUX_MODELS "Flux" SELECTED_FLUX

# Display HiDream selection
select_models HIDREAM_MODELS "HiDream" SELECTED_HIDREAM

# Calculate total size
SDXL_SIZE=$(calculate_size SELECTED_SDXL SDXL_MODELS)
FLUX_SIZE=$(calculate_size SELECTED_FLUX FLUX_MODELS)
HIDREAM_SIZE=$(calculate_size SELECTED_HIDREAM HIDREAM_MODELS)
TOTAL_SIZE=$(echo "$SDXL_SIZE + $FLUX_SIZE + $HIDREAM_SIZE" | bc)

# Display selection summary
echo ""
echo "========================================"
echo "Selection Summary"
echo "========================================"
echo "SDXL Models (${SDXL_SIZE}GB):"
for model in "${SELECTED_SDXL[@]}"; do
    echo "  - $model"
done

echo ""
echo "Flux Models (${FLUX_SIZE}GB):"
for model in "${SELECTED_FLUX[@]}"; do
    echo "  - $model"
done

echo ""
echo "HiDream Models (${HIDREAM_SIZE}GB):"
for model in "${SELECTED_HIDREAM[@]}"; do
    echo "  - $model"
done

echo ""
echo "Total download size: ${TOTAL_SIZE}GB"
echo "Available space: $(df -h /workspace | tail -1 | awk '{print $4}')"

# Ask for confirmation
echo ""
read -p "Do you want to proceed with downloading these models? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Download cancelled."
    exit 0
fi

# Download function
download_model() {
    local url=$1
    local filename=$2
    local subdir=$3
    
    if [ ! -f "$MODELS_PATH/$subdir/$filename" ]; then
        echo "Downloading $filename..."
        wget -q --show-progress -O "$MODELS_PATH/$subdir/$filename" "$url"
        if [ $? -eq 0 ]; then
            echo "✅ $filename downloaded successfully"
        else
            echo "❌ Failed to download $filename"
        fi
    else
        echo "✅ $filename already exists"
    fi
}

# Download selected models
echo ""
echo "========================================"
echo "Downloading Models"
echo "========================================"

# Download SDXL models
for model in "${SELECTED_SDXL[@]}"; do
    url=$(echo "${SDXL_MODELS[$model]}" | cut -d'|' -f2)
    filename=$(basename "$url")
    download_model "$url" "$filename" "checkpoints"
done

# Download Flux models
for model in "${SELECTED_FLUX[@]}"; do
    url=$(echo "${FLUX_MODELS[$model]}" | cut -d'|' -f2)
    filename=$(basename "$url")
    download_model "$url" "$filename" "unet"
done

# Download HiDream models
for model in "${SELECTED_HIDREAM[@]}"; do
    url=$(echo "${HIDREAM_MODELS[$model]}" | cut -d'|' -f2)
    filename=$(basename "$url")
    download_model "$url" "$filename" "checkpoints"
done

echo ""
echo "========================================"
echo "✅ Model download complete!"
echo "========================================"
echo "Total disk space used: ${TOTAL_SIZE}GB"
echo "Models location: $MODELS_PATH"
