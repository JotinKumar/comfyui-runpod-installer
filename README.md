# ComfyUI RunPod Installer 🚀

A comprehensive collection of installation and setup scripts for deploying ComfyUI on RunPod.io with CUDA 12.8 support. This repository provides an automated solution for setting up ComfyUI along with essential models, custom nodes, and support scripts.

## 🌟 Features

- Automated ComfyUI installation for RunPod.io
- CUDA 12.8 compatibility
- Optional custom nodes installation
- Automatic model management
- Google Drive synchronization support
- Package management system

## 📁 Repository Structure

### Core Installation

- `install_comfyui_runpod.sh` - Main installation script for ComfyUI
  - Installs ComfyUI with CUDA 12.8 support
  - Sets up required system packages and dependencies
  - Configures workspace directories and environment
  - Performs disk space checks and error handling

### Support Scripts

- `setup_support_scripts.sh` - Support scripts configuration

  - Sets up maintenance and utility scripts
  - Configures automation tools
  - Manages script permissions and execution
  - Creates necessary directory structure

  #### Custom Nodes and Packages

  - `install_optional_custom_nodes.sh` - Custom nodes installer

    - Provides a curated list of popular ComfyUI custom nodes
    - Handles git clone operations for each custom node
    - Manages dependencies for custom nodes
    - Includes error handling and validation

  - `package_installer.sh` - Advanced package management system
    - Handles GitHub repository installations
    - Manages Python package dependencies
    - Supports both pip and git-based installations
    - Validates package compatibility

  #### Model and Asset Management

  - `download_manager.sh` - Comprehensive model management

    - Supports multiple download sources:
      - Civitai
      - HuggingFace
      - Google Drive
      - Direct URLs
    - Handles various model types and formats
    - Includes checksum verification
    - Organizes models in appropriate directories

  - `gdrive_sync.sh` - Google Drive integration utility
    - Automated Google Drive CLI installation
    - Two-way synchronization support
    - Handles large file transfers
    - Manages authentication and permissions

## 🚀 Getting Started

### Prerequisites

- RunPod.io account
- Container with CUDA 12.8 support
- Sufficient disk space (minimum 10GB recommended)

### RunPod Configuration

#### Basic Pod (Without Persistent Storage)

- **Template**: RunPod CUDA 12.8
- **Container Disk**: 20GB
- **Port**: 8188/http
- **Volume**: Not required
- **Best for**: Quick testing and temporary workloads
  > Note: All data will be lost when pod stops

#### Production Pod (With Persistent Storage)

- **Template**: RunPod CUDA 12.8
- **Container Disk**: 10GB
- **Port**: 8188/http
- **Volume**: 100GB, mount at `/workspace`
- **Best for**: Long-term usage and model storage

> Note: Port 8188 is required for accessing the ComfyUI web interface

### Installation

1. Download the installer script:

```bash
wget https://raw.githubusercontent.com/JotinKumar/comfyui-runpod-installer/main/install_comfyui_runpod.sh
```

2. Make the script executable:

```bash
chmod +x install_comfyui_runpod.sh
```

3. Run the installation script:

```bash
./install_comfyui_runpod.sh
```

The installer will automatically download and set up all necessary support scripts and components.

## 📦 What Gets Installed

- ComfyUI and its dependencies
- Required system packages
- Python dependencies
- CUDA toolkit and related libraries
- Optional custom nodes (if selected)
- Support scripts for model management

## 🔧 Configuration

The installation scripts use the following default paths:

- ComfyUI: `/workspace/ComfyUI`
- Models: `/workspace/comfyui_models`
- Support Scripts: `/workspace/support_scripts`

## 🔌 Optional Custom Nodes

To install optional custom nodes:

```bash
./install_optional_custom_nodes.sh
```

This will provide you with a selection of popular custom nodes to enhance your ComfyUI experience.

## 📥 Model Management

The download manager script provides a comprehensive solution for managing your models:

```bash
./download_manager.sh
```

### Supported Sources

- **Civitai**: Download models from Civitai platform
- **HuggingFace**: Access models from HuggingFace repositories
- **Google Drive**: Download from shared Google Drive links
- **Direct URLs**: Support for direct download links

### Features

- Automatic model categorization
- Checksum verification
- Resume interrupted downloads
- Custom save location support
- Batch download capability

## 🔄 Google Drive Sync

The Google Drive sync utility provides seamless integration with Google Drive:

```bash
./gdrive_sync.sh
```

### Functionality

- **Two-way Sync**: Synchronize both to and from Google Drive
- **Selective Sync**: Choose specific folders to sync
- **Auto-retry**: Handles connection interruptions
- **Large File Support**: Manages large model files efficiently
- **Authentication**: Secure OAuth2 authentication process

### Common Use Cases

- Backing up your models
- Sharing configurations across instances
- Synchronizing output images
- Maintaining consistent workspace across runs

## 🛠️ Troubleshooting

If you encounter any issues:

1. Check available disk space
2. Verify CUDA compatibility
3. Check system logs for error messages
4. Ensure all prerequisites are installed

## 📝 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bugs and feature requests.

## ⭐ Support

If you find this project helpful, please consider giving it a star on GitHub!

## 📞 Contact

For issues and support, please use the GitHub Issues section.
