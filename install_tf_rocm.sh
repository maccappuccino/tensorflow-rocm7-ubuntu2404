#!/bin/bash
set -e

# === CONFIGURATION ===
TF_VERSION="v2.21.0"         # ou "main"
ROCM_VERSION="7.0"
PYTHON_VERSION="3.10"
VENV_PATH="$HOME/miniconda3/envs/tf-rocm7"
CLANG_VERSION="18"

# === 1. Dépendances système ===
echo "🔧 Installation des dépendances système..."
sudo apt update && sudo apt install -y \
    git build-essential zip unzip zlib1g-dev \
    libosmesa6-dev libgl1-mesa-glx libglfw3 \
    libtool autoconf automake cmake \
    clang lld llvm \
    python3-dev python-is-python3 \
    openjdk-17-jdk curl wget gnupg lsb-release

# === 2. Installer Clang 18 depuis apt.llvm.org ===
echo "🧱 Installation Clang $CLANG_VERSION..."
wget -q https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh "$CLANG_VERSION"

# === 3. Clonage du dépôt TensorFlow ===
cd ~
if [ ! -d tensorflow-upstream ]; then
    git clone --recursive https://github.com/tensorflow/tensorflow.git tensorflow-upstream
fi
cd tensorflow-upstream
git fetch
git checkout "$TF_VERSION"

# === 4. Installation Bazelisk ===
echo "📦 Installation de Bazel via bazelisk"
sudo curl -Lo /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64
sudo chmod +x /usr/local/bin/bazel

# === 5. Configuration de TensorFlow ===
export PYTHON_BIN_PATH="$VENV_PATH/bin/python"
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_ROCM=1
export TF_ROCM_VERSION="$ROCM_VERSION"
export TF_ENABLE_XLA=1
export TF_NEED_CUDA=0
export TF_DOWNLOAD_CLANG=0
export TF_CONFIGURE_IOS=0
export CC_OPT_FLAGS="-march=native -O2 -Wno-sign-compare -DEIGEN_STRONG_INLINE=inline"

yes "" | ./configure


# === 7. Compilation TensorFlow ROCm ===
echo "⚙️ Compilation en cours..."
bazel build --config=opt --config=rocm //tensorflow/tools/pip_package:wheel

# === 8. Wheel créée ? ===
WHL_PATH=$(find bazel-bin/tensorflow/tools/pip_package/wheel_house/ -name "*.whl" | head -n1)
if [ ! -f "$WHL_PATH" ]; then
    echo "❌ Wheel non trouvée"
    exit 1
fi

echo "✅ Wheel construite : $WHL_PATH"

# === 9. Installation dans l'env conda ===
"$PYTHON_BIN_PATH" -m pip install "$WHL_PATH"

echo "🎉 TensorFlow ROCm installé avec succès"

# === 10. Test rapide GPU ===
echo "🧪 Test rapide GPU..."
"$PYTHON_BIN_PATH" -c "import tensorflow as tf; print('GPUs detected:', tf.config.list_physical_devices('GPU'))"
