# TensorFlow ROCm 7 — Build from Source (Ubuntu 24.04)

> Compilation de TensorFlow avec ROCm pour GPU AMD (Radeon PRO / Instinct / MI)

---

## 🔧 Matériel testé

- GPU : AMD Radeon AI PRO R9700
- OS : Ubuntu 24.04
- Python : 3.10 (via Miniconda)
- ROCm : 7.0

---

## ⚙️ Pré-requis

- Ubuntu 22.04+ ou 24.04
- Python 3.10 via Miniconda :
  ```bash
  conda create -n tf-rocm7 python=3.10
  conda activate tf-rocm7
  
Téléchargez le wheel : tensorflow-2.21.0.dev0+selfbuilt-cp310-cp310-linux_x86_64.whl
