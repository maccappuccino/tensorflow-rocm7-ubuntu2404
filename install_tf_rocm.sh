#!/bin/bash

set -e

# === CONFIGURABLES ===
TF_VERSION="v2.14.0"  # ou main
ROCM_VERSION="7.0"
PYTHON_VERSION="3.10"
VENV_PATH="$HOME/miniconda3/envs/tf-rocm7"

echo "⚙️ Préparation de l'environnement TensorFlow ROCm $ROCM_VERSION pour Python $PYTHON_VERSION"

# === 1. Dépendances système ===
sudo apt update && sudo apt install -y \
    git build-essential zip unzip zlib1g-dev \
    libosmesa6-dev libgl1-mesa-glx libglfw3 \
    libtool autoconf automake cmake \
    clang lld llvm \
    python3-dev python-is-python3 \
    openjdk-17-jdk curl
    
# === 1.1 Installer Clang 18 depuis les dépôts LLVM officiels
sudo apt install wget gnupg lsb-release
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 18

# === 2. Clonage TensorFlow ===
cd ~
git clone https://github.com/tensorflow/tensorflow.git tensorflow-upstream
cd tensorflow-upstream
git checkout $TF_VERSION

# === 3. Configuration Bazel ===
echo "📦 Installation de Bazel via bazelisk"
sudo curl -Lo /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64
sudo chmod +x /usr/local/bin/bazel

# === 4. Configuration TF ===
export PYTHON_BIN_PATH="$VENV_PATH/bin/python"
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_ROCM=1
export TF_ROCM_VERSION=$ROCM_VERSION
export TF_ENABLE_XLA=1
export CC_OPT_FLAGS="-march=native -O3 -ffast-math"
export TF_CONFIGURE_IOS=0
export TF_NEED_CUDA=0
export TF_DOWNLOAD_CLANG=0

yes "" | ./configure

# === 5. Compilation TensorFlow ROCm ===
bazel build --config=opt --config=rocm //tensorflow/tools/pip_package:wheel \
    --repo_env=HERMETIC_PYTHON_VERSION=$PYTHON_VERSION

# === 6. Wheel créé ===
WHL_PATH=$(find bazel-bin/tensorflow/tools/pip_package/wheel_house/ -name "*.whl" | head -n1)
echo "✅ Wheel créée : $WHL_PATH"

# === 7. Installation dans l'environnement Python actif ===
"$PYTHON_BIN_PATH" -m pip install "$WHL_PATH"
echo "✅ TensorFlow ROCm installé dans $PYTHON_BIN_PATH"
