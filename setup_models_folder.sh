#!/bin/bash
# ComfyUI Models Folder Setup Script for RunPod.io
# This script creates the models folder structure and configures extra_model_paths.yaml

echo "========================================"
echo "📁 Setting up ComfyUI models folder..."
echo "========================================"

# Create models folder structure
echo "----------------------------------------"
echo "📁 Creating models folder structure..."
echo "----------------------------------------"
cd /workspace
mkdir -p comfyui_models

cd comfyui_models
mkdir -p checkpoints
mkdir -p loras
mkdir -p vae
mkdir -p clip
mkdir -p clip_vision
mkdir -p configs
mkdir -p controlnet
mkdir -p diffusion_models
mkdir -p unet
mkdir -p embeddings
mkdir -p hypernetworks
mkdir -p upscale_models
mkdir -p ipadapter
mkdir -p animatediff_models
mkdir -p ultralytics_bbox
mkdir -p ultralytics_segm
mkdir -p sams
mkdir -p mmdets
mkdir -p insightface
echo "✅ Models folder structure created"

# Create extra_model_paths.yaml configuration
echo "----------------------------------------"
echo "⚙️ Creating extra_model_paths.yaml configuration..."
echo "----------------------------------------"
cd /workspace/ComfyUI

# Backup existing extra_model_paths.yaml if it exists
if [ -f "extra_model_paths.yaml" ]; then
    cp extra_model_paths.yaml extra_model_paths.yaml.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Existing extra_model_paths.yaml backed up"
fi

# Create new extra_model_paths.yaml
cat > extra_model_paths.yaml << 'EOF'
# ComfyUI Extra Model Paths Configuration
# This file tells ComfyUI where to find additional models

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

# Optional: Add paths for other UI installations if you have them
# a111:
#   base_path: /path/to/stable-diffusion-webui/
#   checkpoints: models/Stable-diffusion
#   configs: models/Stable-diffusion
#   vae: models/VAE
#   loras: |
#     models/Lora
#     models/LyCORIS
#   upscale_models: |
#     models/ESRGAN
#     models/RealESRGAN
#     models/SwinIR
#   embeddings: embeddings
#   hypernetworks: models/hypernetworks
#   controlnet: models/ControlNet
EOF
echo "✅ extra_model_paths.yaml configuration created"

echo ""
echo "========================================"
echo "✨ Models folder setup complete! ✨"
echo "========================================"
echo ""
echo "📁 Models folder created at: /workspace/comfyui_models"
echo "⚙️ Model paths configured in: /workspace/ComfyUI/extra_model_paths.yaml"
echo ""
echo "You can now place your model files in the appropriate subdirectories:"
echo "- checkpoints: Main model files (e.g., SDXL, SD 1.5)"
echo "- loras: LoRA model files"
echo "- vae: VAE files"
echo "- controlnet: ControlNet models"
echo "- ipadapter: IP-Adapter models"
echo "- And other model types in their respective folders"
echo ""
echo "Remember to restart ComfyUI after adding new models for them to be recognized."
