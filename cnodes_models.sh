#!/bin/bash
# Script to install supporting models and custom nodes for IPAdapter, ControlNet, PuLID, InstantID, Upscaling, SAM, Flux, and HiDream (SDXL and Flux only)

echo "========================================"
echo "Installing supporting components..."
echo "========================================"

# Set paths
COMFYUI_PATH="/workspace/ComfyUI"
MODELS_PATH="/workspace/comfyui_models"
CUSTOM_NODES_PATH="$COMFYUI_PATH/custom_nodes"

# Create model directories
mkdir -p "$MODELS_PATH"/{clip,vae,insightface,ipadapter,pulid,upscale_models,sams,controlnet}

# Install custom nodes (if not already installed)
install_custom_node() {
    local repo_url=$1
    local node_name=$2
    local target_dir="$CUSTOM_NODES_PATH/$node_name"
    
    if [ ! -d "$target_dir" ]; then
        echo "Installing $node_name..."
        git clone "$repo_url" "$target_dir"
        if [ -f "$target_dir/requirements.txt" ]; then
            cd "$target_dir"
            pip install -r requirements.txt
            cd "$COMFYUI_PATH"
        fi
        echo "✅ $node_name installed"
    else
        echo "✅ $node_name already exists, updating..."
        cd "$target_dir"
        git pull
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt
        fi
        cd "$COMFYUI_PATH"
    fi
}

# Install required custom nodes
install_custom_node "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git" "ComfyUI_IPAdapter_plus"
install_custom_node "https://github.com/cubiq/ComfyUI_InstantID.git" "ComfyUI_InstantID"
install_custom_node "https://github.com/cubiq/ComfyUI-PuLID.git" "ComfyUI-PuLID"
install_custom_node "https://github.com/Fannovel16/comfyui_controlnet_aux.git" "comfyui_controlnet_aux"
install_custom_node "https://github.com/continue-revolution/ComfyUI-segment-anything.git" "ComfyUI-segment-anything"
install_custom_node "https://github.com/blaise-tk/ComfyUI_Swin2SR.git" "ComfyUI_Swin2SR"

# Download models (if not exists)
download_model() {
    local url=$1
    local filename=$2
    local subdir=$3
    
    if [ ! -f "$MODELS_PATH/$subdir/$filename" ]; then
        echo "Downloading $filename..."
        wget -q --show-progress -O "$MODELS_PATH/$subdir/$filename" "$url"
        echo "✅ $filename downloaded"
    else
        echo "✅ $filename already exists"
    fi
}

# Download CLIP models
download_model "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" "clip_l.safetensors" "clip"
download_model "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" "t5xxl_fp16.safetensors" "clip"

# Download VAE models
download_model "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors" "sdxl_vae.safetensors" "vae"
download_model "https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors" "ae.safetensors" "vae"

# Download IPAdapter models (SDXL and Flux only)
download_model "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sdxl.safetensors" "ip-adapter_sdxl.safetensors" "ipadapter"
download_model "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sdxl_plus.safetensors" "ip-adapter_sdxl_plus.safetensors" "ipadapter"
download_model "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sdxl_plus_face.safetensors" "ip-adapter_sdxl_plus_face.safetensors" "ipadapter"
download_model "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_flux.safetensors" "ip-adapter_flux.safetensors" "ipadapter"

# Download InstantID models (SDXL and Flux only)
download_model "https://huggingface.co/InstantID/InstantID/resolve/main/InstantID/ControlNetModel/ControlNetModel_sdxl.safetensors" "ControlNetModel_sdxl.safetensors" "ipadapter"
download_model "https://huggingface.co/InstantID/InstantID/resolve/main/InstantID/IPAdapter/IPAdapter_sdxl.safetensors" "IPAdapter_sdxl.safetensors" "ipadapter"
download_model "https://huggingface.co/InstantID/InstantID/resolve/main/InstantID/ControlNetModel/ControlNetModel_flux.safetensors" "ControlNetModel_flux.safetensors" "ipadapter"
download_model "https://huggingface.co/InstantID/InstantID/resolve/main/InstantID/IPAdapter/IPAdapter_flux.safetensors" "IPAdapter_flux.safetensors" "ipadapter"

# Download PuLID models (SDXL and Flux only)
download_model "https://huggingface.co/guoyww/animatediff/resolve/main/pulid_flux_v1.safetensors" "pulid_flux_v1.safetensors" "pulid"
download_model "https://huggingface.co/guoyww/animatediff/resolve/main/pulid_sdxl_v1.safetensors" "pulid_sdxl_v1.safetensors" "pulid"

# Download ControlNet models (SDXL and Flux only)
# SDXL ControlNet models
download_model "https://huggingface.co/diffusers/controlnet-canny-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors" "controlnet-canny-sdxl-1.0.safetensors" "controlnet"
download_model "https://huggingface.co/diffusers/controlnet-depth-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors" "controlnet-depth-sdxl-1.0.safetensors" "controlnet"
download_model "https://huggingface.co/thibaud/controlnet-openpose-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors" "controlnet-openpose-sdxl-1.0.safetensors" "controlnet"

# Flux ControlNet models
download_model "https://huggingface.co/InstantID/FLUX.1-dev-ControlNet-Canny/resolve/main/diffusion_pytorch_model.safetensors" "flux-dev-canny.safetensors" "controlnet"
download_model "https://huggingface.co/InstantID/FLUX.1-dev-ControlNet-Depth/resolve/main/diffusion_pytorch_model.safetensors" "flux-dev-depth.safetensors" "controlnet"
download_model "https://huggingface.co/InstantID/FLUX.1-dev-ControlNet-OpenPose/resolve/main/diffusion_pytorch_model.safetensors" "flux-dev-openpose.safetensors" "controlnet"

# Download Upscaling Models
download_model "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-general-x4v3.pth" "realesr-general-x4v3.pth" "upscale_models"
download_model "https://github.com/JingyunLiang/SwinIR/releases/download/v0.0/001_classicalSR_DF2K_s64w8_SwinIR-M_x4.pth" "swinir_4x.pth" "upscale_models"
download_model "https://github.com/XPixelGroup/HAT/releases/download/v0.1/HAT_SRx4_ImageNet-pretrain.pth" "HAT_SRx4_ImageNet-pretrain.pth" "upscale_models"
download_model "https://github.com/XPixelGroup/HAT/releases/download/v0.1/OmniSR_X4.pth" "OmniSR_X4.pth" "upscale_models"
download_model "https://github.com/TencentARC/GFPGAN/releases/download/v1.3.4/GFPGANv1.4.pth" "GFPGANv1.4.pth" "upscale_models"

# Additional Upscaling Models
download_model "https://github.com/cszn/BSRGAN/releases/download/v1.0/BSRGAN.pth" "BSRGAN.pth" "upscale_models"
download_model "https://github.com/mv-lab/swin2sr/releases/download/v1.0/Swin2SR_ClassicalSR_X2_64.pth" "Swin2SR_X2.pth" "upscale_models"
download_model "https://github.com/mv-lab/swin2sr/releases/download/v1.0/Swin2SR_ClassicalSR_X4_64.pth" "Swin2SR_X4.pth" "upscale_models"
download_model "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/RealESRGAN_x2plus.pth" "RealESRGAN_x2plus.pth" "upscale_models"
download_model "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/RealESRGAN_x4plus.pth" "RealESRGAN_x4plus.pth" "upscale_models"

# Download SAM Models
download_model "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth" "sam_vit_h_4b8939.pth" "sams"
download_model "https://github.com/SysCV/sam-hq/releases/download/v0.1/sam_hq_vit_h.pth" "sam_hq_vit_h.pth" "sams"

# Download InsightFace models (if not exists)
if [ ! -d "$MODELS_PATH/insightface/models" ]; then
    echo "Downloading InsightFace models..."
    mkdir -p "$MODELS_PATH/insightface"
    cd "$MODELS_PATH/insightface"
    
    # Download buffalo_l model
    if [ ! -f "buffalo_l.zip" ]; then
        wget -q --show-progress -O buffalo_l.zip "https://github.com/cubiq/ComfyUI_IPAdapter_plus/raw/main/models/insightface/buffalo_l.zip"
        unzip -q buffalo_l.zip -d buffalo_l
        rm buffalo_l.zip
    fi
    
    # Download antelopev2 model
    if [ ! -f "antelopev2.zip" ]; then
        wget -q --show-progress -O antelopev2.zip "https://github.com/cubiq/ComfyUI_IPAdapter_plus/raw/main/models/insightface/antelopev2.zip"
        unzip -q antelopev2.zip -d antelopev2
        rm antelopev2.zip
    fi
    
    # Create models directory and move buffalo_l model
    mkdir -p models
    mv buffalo_l/* models/
    rmdir buffalo_l
    
    echo "✅ InsightFace models downloaded"
    cd "$COMFYUI_PATH"
else
    echo "✅ InsightFace models already exist"
fi

# Create symlinks for InsightFace models in custom nodes
create_symlink() {
    local target="$1"
    local link_name="$2"
    
    if [ ! -L "$link_name" ] && [ ! -d "$link_name" ]; then
        ln -s "$target" "$link_name"
        echo "✅ Created symlink: $link_name -> $target"
    elif [ -L "$link_name" ]; then
        echo "✅ Symlink already exists: $link_name"
    else
        echo "⚠️ Directory already exists: $link_name"
    fi
}

# Create symlinks for InsightFace models
create_symlink "$MODELS_PATH/insightface" "$CUSTOM_NODES_PATH/ComfyUI_IPAdapter_plus/models/insightface"
create_symlink "$MODELS_PATH/insightface" "$CUSTOM_NODES_PATH/ComfyUI_InstantID/models/insightface"
create_symlink "$MODELS_PATH/insightface" "$CUSTOM_NODES_PATH/ComfyUI-PuLID/models/insightface"

# Update extra_model_paths.yaml if needed
if [ ! -f "$COMFYUI_PATH/extra_model_paths.yaml" ]; then
    echo "Creating extra_model_paths.yaml..."
    cat > "$COMFYUI_PATH/extra_model_paths.yaml" << 'EOF'
comfyui_models:
  base_path: /workspace/comfyui_models/
  is_default: true
  checkpoints: checkpoints/
  clip: clip/
  vae: vae/
  controlnet: controlnet/
  ipadapter: ipadapter/
  pulid: pulid/
  insightface: insightface/
  upscale_models: upscale_models/
  sams: sams/
EOF
    echo "✅ extra_model_paths.yaml created"
else
    echo "✅ extra_model_paths.yaml already exists"
fi

echo ""
echo "========================================"
echo "✅ Supporting components installation complete!"
echo "========================================"
echo ""
echo "Summary of installed components:"
echo "- Custom nodes: ComfyUI_IPAdapter_plus, ComfyUI_InstantID, ComfyUI-PuLID, comfyui_controlnet_aux, ComfyUI-segment-anything, ComfyUI_Swin2SR"
echo "- CLIP models: clip_l.safetensors, t5xxl_fp16.safetensors"
echo "- VAE models: sdxl_vae.safetensors, ae.safetensors"
echo "- IPAdapter models: SDXL (3 models), Flux (1 model)"
echo "- InstantID models: SDXL (2 models), Flux (2 models)"
echo "- PuLID models: SDXL (1 model), Flux (1 model)"
echo "- ControlNet models: SDXL (3 models), Flux (3 models)"
echo "- Upscaling models: Real-ESRGAN (3 versions), SwinIR, HAT, Omni-SR, GFPGAN, BSRGAN, Swin2SR (2 versions)"
echo "- SAM models: SAM ViT-H, SAM-HQ ViT-H"
echo "- InsightFace models: buffalo_l, antelopev2"
echo ""
echo "Disk space used: ~22GB"
echo "Models location: /workspace/comfyui_models"
echo "Custom nodes location: /workspace/ComfyUI/custom_nodes"
