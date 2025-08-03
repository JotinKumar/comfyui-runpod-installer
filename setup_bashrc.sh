#!/bin/bash
# Setup .bashrc for ComfyUI on RunPod.io

echo "Setting up .bashrc for ComfyUI..."

# Backup existing .bashrc
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

# Add ComfyUI environment variables to .bashrc
cat >> ~/.bashrc << 'EOF'

# ComfyUI Environment Variables - Added by setup script
export PATH="/workspace/ComfyUI/.venv/bin:$PATH"
export PYTHONPATH="/workspace/ComfyUI:$PYTHONPATH"
export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# ComfyUI aliases
alias comfyui="cd /workspace/ComfyUI && python main.py --listen --port 8188"
alias comfy="cd /workspace/ComfyUI"
alias activate_comfy="source /workspace/ComfyUI/.venv/bin/activate"
EOF

echo "✅ .bashrc updated successfully"
echo "🔄 Reloading .bashrc..."
source ~/.bashrc
echo "✅ .bashrc reloaded"

# Verify setup
echo ""
echo "🔍 Verifying setup..."
echo "PATH: $PATH"
echo "PYTHONPATH: $PYTHONPATH"
echo "CUDA_HOME: $CUDA_HOME"
echo ""
echo "✅ Setup complete! You can now use:"
echo "  - 'comfyui' to start ComfyUI"
echo "  - 'comfy' to navigate to ComfyUI directory"
echo "  - 'activate_comfy' to activate virtual environment"
