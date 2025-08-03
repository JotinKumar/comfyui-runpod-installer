# ComfyUI RunPod.io Installer

Automated installation script for ComfyUI on RunPod.io with NVIDIA 5090 support.

## Features

- Python 3.11 with uv virtual environment
- CUDA 12.8 support for RTX 5090
- Essential custom nodes pre-installed
- Automated .bashrc configuration
- Separate models folder setup with extra_model_paths.yaml configuration

## Quick Start

### Direct Installation

```bash
# SSH into your RunPod instance
cd /workspace

# Download and run the installer
wget https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/install_comfyui_runpod.sh
chmod +x install_comfyui_runpod.sh
./install_comfyui_runpod.sh

# Setup .bashrc
wget https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/setup_bashrc.sh
chmod +x setup_bashrc.sh
./setup_bashrc.sh

# Setup models folder
wget https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/setup_models_folder.sh
chmod +x setup_models_folder.sh
./setup_models_folder.sh

# Start ComfyUI
comfyui
