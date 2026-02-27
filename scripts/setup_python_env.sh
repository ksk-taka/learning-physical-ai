#!/bin/bash
# =============================================================================
# Python環境 + AI系ライブラリ セットアップスクリプト
# =============================================================================
#
# 概要:
#   Miniconda を使用して Physical AI 開発用の Python 環境を構築し、
#   PyTorch、Hugging Face、コンピュータビジョン等の AI/ML ライブラリを
#   インストールするスクリプト。
#
# 対象マシン:
#   - Intel Core Ultra 9 275HX / 32GB RAM / RTX 5070 (8GB VRAM)
#   - WSL2 Ubuntu 22.04
#   - CUDA 12.x インストール済み
#
# 前提条件:
#   - setup_wsl2.sh が実行済みであること
#   - setup_cuda_wsl2.sh が実行済みであること（GPU サポートに必要）
#
# 使い方:
#   chmod +x setup_python_env.sh
#   ./setup_python_env.sh
#
# 注意:
#   - 冪等性あり（何度実行しても安全）
#   - conda 環境 "physical-ai" を作成します
#   - 約 10-15GB のディスク容量が必要です
# =============================================================================

set -euo pipefail

# --- 色定義 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- ログ関数 ---
log_info() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $*"
}

log_step() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# --- エラーハンドリング ---
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "スクリプトがエラーで終了しました (exit code: $exit_code)"
        log_error "エラーが発生した行: ${BASH_LINENO[0]}"
        log_error "Python 環境のセットアップが不完全な可能性があります"
        log_error "エラーを修正してから再実行してください"
    fi
}
trap cleanup EXIT

# --- ユーティリティ関数 ---
is_cmd_available() {
    command -v "$1" &>/dev/null
}

# --- 設定 ---
CONDA_ENV_NAME="physical-ai"
PYTHON_VERSION="3.10"
CONDA_DIR="$HOME/miniconda3"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# =============================================================================
# Step 1: Miniconda のインストール
# =============================================================================
log_step "Step 1: Miniconda のインストール"

# conda がインストールされているか確認
if is_cmd_available "conda"; then
    CONDA_VER=$(conda --version 2>/dev/null)
    log_success "conda は既にインストール済みです: $CONDA_VER"
else
    # Miniconda のインストールディレクトリ確認
    if [ -d "$CONDA_DIR" ] && [ -f "$CONDA_DIR/bin/conda" ]; then
        log_info "Miniconda ディレクトリが見つかりましたが、PATH に含まれていません"
        log_info "conda を初期化します..."
        eval "$("$CONDA_DIR/bin/conda" shell.bash hook)"
    else
        log_info "Miniconda をインストールします..."

        # Miniconda インストーラのダウンロード
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        MINICONDA_INSTALLER="/tmp/miniconda_installer.sh"

        if [ ! -f "$MINICONDA_INSTALLER" ]; then
            log_info "Miniconda インストーラをダウンロードします..."
            wget -q --show-progress "$MINICONDA_URL" -O "$MINICONDA_INSTALLER"
        fi

        # バッチモードでインストール（対話なし）
        log_info "Miniconda をインストールしています..."
        bash "$MINICONDA_INSTALLER" -b -p "$CONDA_DIR"

        # インストーラのクリーンアップ
        rm -f "$MINICONDA_INSTALLER"

        log_success "Miniconda インストール完了: $CONDA_DIR"
    fi

    # conda を現在のシェルで使えるようにする
    eval "$("$CONDA_DIR/bin/conda" shell.bash hook)"

    # bash への conda 初期化（.bashrc に追加）
    if ! grep -q "conda initialize" "$HOME/.bashrc" 2>/dev/null; then
        log_info "conda を bash に初期化します..."
        "$CONDA_DIR/bin/conda" init bash
        log_success "conda の bash 初期化完了"
    else
        log_info "conda の bash 初期化は既に設定済みです"
    fi
fi

# conda のアップデート
log_info "conda を最新バージョンに更新します..."
conda update -n base -c defaults conda -y 2>/dev/null || {
    log_warn "conda のアップデートに失敗しました（ネットワーク接続を確認してください）"
}

# =============================================================================
# Step 2: conda 環境の作成
# =============================================================================
log_step "Step 2: conda 環境 '${CONDA_ENV_NAME}' の作成 (Python ${PYTHON_VERSION})"

# 環境が既に存在するか確認
if conda env list 2>/dev/null | grep -q "^${CONDA_ENV_NAME} "; then
    log_warn "conda 環境 '${CONDA_ENV_NAME}' は既に存在します"
    log_info "既存の環境を使用します（再作成するには 'conda env remove -n ${CONDA_ENV_NAME}' を実行）"
else
    log_info "conda 環境を作成します: ${CONDA_ENV_NAME} (Python ${PYTHON_VERSION})"
    conda create -n "${CONDA_ENV_NAME}" python="${PYTHON_VERSION}" -y
    log_success "conda 環境 '${CONDA_ENV_NAME}' 作成完了"
fi

# =============================================================================
# Step 3: 環境のアクティベート
# =============================================================================
log_step "Step 3: conda 環境のアクティベート"

log_info "環境 '${CONDA_ENV_NAME}' をアクティベートします..."
conda activate "${CONDA_ENV_NAME}" || {
    log_error "conda 環境のアクティベートに失敗しました"
    log_info "シェルを再起動してから再実行してください"
    exit 1
}

PYTHON_VER=$(python --version 2>/dev/null)
log_success "Python 環境アクティブ: $PYTHON_VER"

# pip の更新
log_info "pip を最新バージョンに更新します..."
pip install --upgrade pip setuptools wheel

# =============================================================================
# Step 4: PyTorch + CUDA サポートのインストール
# =============================================================================
log_step "Step 4: PyTorch + CUDA サポートのインストール"

# PyTorch がインストール済みかチェック
PYTORCH_INSTALLED=false
if python -c "import torch; print(torch.__version__)" 2>/dev/null; then
    PYTORCH_INSTALLED=true
    TORCH_VER=$(python -c "import torch; print(torch.__version__)" 2>/dev/null)
    CUDA_AVAILABLE=$(python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null)
    log_info "PyTorch は既にインストール済みです: $TORCH_VER (CUDA: $CUDA_AVAILABLE)"
fi

if [ "$PYTORCH_INSTALLED" = false ]; then
    log_info "PyTorch を CUDA サポート付きでインストールします..."
    log_info "CUDA 12.4 対応バージョンをインストールします"
    log_info "（RTX 5070 には CUDA 12.4 以上が推奨）"

    # PyTorch の公式インストールコマンド（CUDA 12.4 対応）
    # 注意: RTX 5070 (Blackwell) は最新の PyTorch が必要
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

    log_success "PyTorch インストール完了"
fi

# =============================================================================
# Step 5: AI/ML ライブラリのインストール
# =============================================================================
log_step "Step 5: AI/ML ライブラリのインストール"

log_info "Hugging Face 系ライブラリをインストールします..."
pip install \
    transformers \
    accelerate \
    bitsandbytes \
    optimum \
    sentence-transformers \
    datasets \
    tokenizers \
    safetensors \
    huggingface-hub

log_success "Hugging Face ライブラリインストール完了"

# vLLM のインストール（高速推論エンジン）
log_info "vLLM (高速 LLM 推論エンジン) のインストールを試みます..."
pip install vllm 2>/dev/null || {
    log_warn "vLLM のインストールに失敗しました"
    log_warn "vLLM は特定の CUDA バージョンとの互換性が必要です"
    log_warn "後で手動インストールが必要な場合があります:"
    log_warn "  pip install vllm"
}

# Whisper（音声認識）
log_info "OpenAI Whisper (音声認識) をインストールします..."
pip install openai-whisper 2>/dev/null || {
    log_warn "openai-whisper のインストールに失敗しました"
    log_info "代替: pip install faster-whisper を試してください"
}

# faster-whisper (Whisper の高速版)
pip install faster-whisper 2>/dev/null || {
    log_warn "faster-whisper のインストールに失敗しました（オプション）"
}

log_success "AI/ML ライブラリインストール完了"

# =============================================================================
# Step 6: コンピュータビジョンライブラリのインストール
# =============================================================================
log_step "Step 6: コンピュータビジョンライブラリのインストール"

log_info "CV 関連ライブラリをインストールします..."
pip install \
    opencv-python-headless \
    Pillow \
    scikit-image \
    albumentations

log_success "基本 CV ライブラリインストール完了"

# Open3D（3D ポイントクラウド処理）
log_info "Open3D (3D 点群処理ライブラリ) をインストールします..."
pip install open3d 2>/dev/null || {
    log_warn "Open3D のインストールに失敗しました"
    log_warn "Python ${PYTHON_VERSION} との互換性を確認してください"
    log_warn "手動インストール: pip install open3d"
}

log_success "コンピュータビジョンライブラリインストール完了"

# =============================================================================
# Step 7: ROS 2 Python ツールのインストール
# =============================================================================
log_step "Step 7: ROS 2 Python ツールの備考"

# 重要な注意: ROS 2 の Python パッケージは conda 環境とは分離されている
# ROS 2 のパッケージは apt でインストールされ、システム Python を使用する
# conda 環境内で ROS 2 を使う場合は注意が必要

log_info "ROS 2 Python パッケージは apt 経由で管理されています"
log_info "conda 環境内から ROS 2 を使う場合の注意:"
log_info "  - source /opt/ros/humble/setup.bash を実行してパスを設定"
log_info "  - conda 環境と ROS 2 システムパッケージの混在に注意"

# ROS 2 開発に使える追加ツール（conda 内にインストール）
log_info "ROS 2 開発補助ツールをインストールします..."
pip install \
    catkin-pkg \
    empy==3.3.4 \
    lark \
    pyyaml \
    numpy-quaternion 2>/dev/null || {
    log_warn "一部の ROS 2 補助ツールのインストールに失敗しました"
}

log_success "ROS 2 Python ツールのセットアップ完了"

# =============================================================================
# Step 8: 開発ツールのインストール
# =============================================================================
log_step "Step 8: 開発ツールのインストール"

log_info "JupyterLab と可視化ライブラリをインストールします..."
pip install \
    jupyterlab \
    notebook \
    ipywidgets \
    matplotlib \
    seaborn \
    plotly \
    bokeh

log_success "JupyterLab + 可視化ツールインストール完了"

log_info "データサイエンスライブラリをインストールします..."
pip install \
    pandas \
    numpy \
    scipy \
    scikit-learn \
    sympy \
    tqdm \
    rich

log_success "データサイエンスライブラリインストール完了"

log_info "コード品質ツールをインストールします..."
pip install \
    black \
    flake8 \
    mypy \
    isort \
    pylint \
    pytest \
    pytest-cov \
    pre-commit

log_success "コード品質ツールインストール完了"

# =============================================================================
# Step 9: ONNX / TensorRT Python バインディングのインストール
# =============================================================================
log_step "Step 9: ONNX / TensorRT Python バインディング"

log_info "ONNX 関連ライブラリをインストールします..."
pip install \
    onnx \
    onnxruntime-gpu 2>/dev/null || {
    log_warn "onnxruntime-gpu のインストールに失敗しました"
    log_info "CPU 版をインストールします..."
    pip install onnxruntime || log_warn "onnxruntime のインストールに失敗しました"
}

log_info "TensorRT Python バインディングのインストールを試みます..."
pip install tensorrt 2>/dev/null || {
    log_warn "TensorRT Python バインディングのインストールに失敗しました"
    log_info "TensorRT は NVIDIA Developer サイトから手動インストールが必要な場合があります"
    log_info "または: pip install nvidia-tensorrt"
    pip install nvidia-tensorrt 2>/dev/null || {
        log_warn "nvidia-tensorrt も利用できません（後で手動インストールしてください）"
    }
}

# pycuda（CUDA の Python バインディング）
pip install pycuda 2>/dev/null || {
    log_warn "pycuda のインストールに失敗しました（CUDA 開発環境が必要）"
}

log_success "ONNX / TensorRT セットアップ完了"

# =============================================================================
# Step 10: インストールの検証
# =============================================================================
log_step "Step 10: インストールの検証"

echo ""
log_info "Python 環境情報を確認します..."
echo ""

python << 'VERIFY_SCRIPT'
import sys
import importlib

GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
NC = "\033[0m"

print(f"  Python バージョン: {sys.version}")
print(f"  Python パス:       {sys.executable}")
print()

# テストするライブラリとその説明
libraries = [
    ("torch", "PyTorch (Deep Learning)"),
    ("torchvision", "TorchVision (CV for PyTorch)"),
    ("torchaudio", "TorchAudio (Audio for PyTorch)"),
    ("transformers", "Hugging Face Transformers"),
    ("accelerate", "Hugging Face Accelerate"),
    ("bitsandbytes", "BitsAndBytes (Quantization)"),
    ("sentence_transformers", "Sentence Transformers"),
    ("vllm", "vLLM (Fast Inference)"),
    ("cv2", "OpenCV"),
    ("open3d", "Open3D (3D Point Clouds)"),
    ("PIL", "Pillow (Image Processing)"),
    ("skimage", "scikit-image"),
    ("sklearn", "scikit-learn"),
    ("pandas", "Pandas (Data Analysis)"),
    ("numpy", "NumPy (Numerical Computing)"),
    ("scipy", "SciPy (Scientific Computing)"),
    ("matplotlib", "Matplotlib (Visualization)"),
    ("seaborn", "Seaborn (Statistical Viz)"),
    ("plotly", "Plotly (Interactive Viz)"),
    ("onnx", "ONNX (Model Format)"),
    ("onnxruntime", "ONNX Runtime"),
    ("jupyterlab", "JupyterLab"),
    ("black", "Black (Code Formatter)"),
    ("pytest", "Pytest (Testing)"),
]

ok_count = 0
fail_count = 0

print("  === ライブラリインストール状況 ===")
print()

for module_name, description in libraries:
    try:
        mod = importlib.import_module(module_name)
        version = getattr(mod, "__version__", "N/A")
        print(f"  {GREEN}[OK]{NC} {description}: {version}")
        ok_count += 1
    except ImportError:
        print(f"  {YELLOW}[--]{NC} {description}: 未インストール")
        fail_count += 1

print()
print(f"  インストール済み: {ok_count}/{ok_count + fail_count}")

# PyTorch GPU テスト
print()
print("  === GPU テスト ===")
print()
try:
    import torch
    if torch.cuda.is_available():
        print(f"  {GREEN}[OK]{NC} CUDA 利用可能: True")
        print(f"  {GREEN}[OK]{NC} CUDA バージョン: {torch.version.cuda}")
        print(f"  {GREEN}[OK]{NC} cuDNN バージョン: {torch.backends.cudnn.version()}")
        print(f"  {GREEN}[OK]{NC} GPU デバイス: {torch.cuda.get_device_name(0)}")

        # GPU メモリ情報
        total_mem = torch.cuda.get_device_properties(0).total_mem / (1024**3)
        print(f"  {GREEN}[OK]{NC} GPU メモリ: {total_mem:.1f} GB")

        # 簡単な GPU 計算テスト
        x = torch.randn(1000, 1000, device='cuda')
        y = torch.randn(1000, 1000, device='cuda')
        z = torch.mm(x, y)
        print(f"  {GREEN}[OK]{NC} GPU 行列計算テスト: 成功 (1000x1000 行列乗算)")
    else:
        print(f"  {YELLOW}[--]{NC} CUDA 利用不可")
        print(f"       CUDA Toolkit と GPU ドライバを確認してください")
except ImportError:
    print(f"  {YELLOW}[--]{NC} PyTorch 未インストール（GPU テストスキップ）")
except Exception as e:
    print(f"  {RED}[NG]{NC} GPU テスト失敗: {e}")
VERIFY_SCRIPT

echo ""
log_success "インストール検証完了"

# =============================================================================
# Step 11: requirements.txt の生成
# =============================================================================
log_step "Step 11: requirements.txt の生成"

REQUIREMENTS_FILE="${PROJECT_ROOT}/requirements.txt"

log_info "requirements.txt を ${REQUIREMENTS_FILE} に生成します..."

cat > "$REQUIREMENTS_FILE" << 'REQUIREMENTS'
# =============================================================================
# Physical AI Learning Project - Python Dependencies
# =============================================================================
# 生成方法: setup_python_env.sh によって自動生成
# 環境再現: pip install -r requirements.txt
#
# 注意:
#   - PyTorch は CUDA バージョンに依存するため、別途インストールが必要:
#     pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
#   - 一部のパッケージはオプションです（インストールに失敗しても問題なく使えます）
# =============================================================================

# --- Deep Learning Framework ---
# torch, torchvision, torchaudio は CUDA バージョン依存のため requirements.txt からは除外
# 上記の注意を参照してください

# --- Hugging Face ---
transformers
accelerate
bitsandbytes
optimum
sentence-transformers
datasets
tokenizers
safetensors
huggingface-hub

# --- LLM Inference ---
# vllm  # CUDA バージョン依存、手動インストール推奨

# --- Speech ---
openai-whisper
faster-whisper

# --- Computer Vision ---
opencv-python-headless
Pillow
scikit-image
albumentations
open3d

# --- Data Science ---
pandas
numpy
scipy
scikit-learn
sympy
tqdm
rich

# --- Visualization ---
matplotlib
seaborn
plotly
bokeh
ipywidgets

# --- ONNX / TensorRT ---
onnx
onnxruntime-gpu
# tensorrt  # NVIDIA から手動インストール推奨
# pycuda    # CUDA 開発環境依存

# --- Development Tools ---
jupyterlab
notebook
black
flake8
mypy
isort
pylint
pytest
pytest-cov
pre-commit

# --- ROS 2 Helpers ---
catkin-pkg
empy==3.3.4
lark
pyyaml
numpy-quaternion

# --- Robotics / Simulation ---
# gymnasium  # 強化学習環境（必要に応じて追加）
# stable-baselines3  # 強化学習アルゴリズム（必要に応じて追加）
REQUIREMENTS

log_success "requirements.txt 生成完了: ${REQUIREMENTS_FILE}"

# 現在のインストール状況も pip freeze で保存
FREEZE_FILE="${PROJECT_ROOT}/requirements-freeze.txt"
log_info "pip freeze の結果も保存します: ${FREEZE_FILE}"
pip freeze > "$FREEZE_FILE"
log_success "requirements-freeze.txt 生成完了"

# =============================================================================
# Step 12: サマリー表示
# =============================================================================
log_step "Step 12: インストールサマリー"

echo ""
echo -e "${GREEN}=== Python 環境セットアップ結果 ===${NC}"
echo ""
echo -e "  conda 環境名:     ${GREEN}${CONDA_ENV_NAME}${NC}"
echo -e "  Python バージョン: ${GREEN}$(python --version 2>/dev/null)${NC}"
echo -e "  pip バージョン:    ${GREEN}$(pip --version 2>/dev/null | awk '{print $2}')${NC}"
echo -e "  環境パス:         ${GREEN}$(conda info --envs 2>/dev/null | grep "${CONDA_ENV_NAME}" | awk '{print $NF}')${NC}"
echo ""

# PyTorch 情報
python -c "
import torch
print(f'  PyTorch:           \033[0;32m{torch.__version__}\033[0m')
print(f'  CUDA (PyTorch):    \033[0;32m{torch.version.cuda if torch.cuda.is_available() else \"N/A\"}\033[0m')
print(f'  GPU:               \033[0;32m{torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}\033[0m')
" 2>/dev/null || echo -e "  PyTorch:           ${YELLOW}未確認${NC}"

echo ""
echo -e "  requirements.txt:  ${GREEN}${REQUIREMENTS_FILE}${NC}"
echo -e "  freeze ファイル:   ${GREEN}${FREEZE_FILE}${NC}"

# インストール済みパッケージ数
PKG_COUNT=$(pip list 2>/dev/null | wc -l)
echo ""
echo -e "  インストール済みパッケージ数: ${GREEN}${PKG_COUNT}${NC}"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}  Python 環境のセットアップが完了しました！${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${YELLOW}使い方:${NC}"
echo "  conda activate ${CONDA_ENV_NAME}    # 環境をアクティベート"
echo "  conda deactivate                    # 環境を無効化"
echo "  jupyter lab                         # JupyterLab を起動"
echo "  python -c 'import torch; print(torch.cuda.is_available())'  # GPU テスト"
echo ""
echo -e "${YELLOW}環境の再現:${NC}"
echo "  conda create -n ${CONDA_ENV_NAME} python=${PYTHON_VERSION} -y"
echo "  conda activate ${CONDA_ENV_NAME}"
echo "  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124"
echo "  pip install -r requirements.txt"
echo ""
echo -e "${YELLOW}注意事項:${NC}"
echo "  - ROS 2 と conda を併用する場合は環境変数の衝突に注意してください"
echo "  - GPU メモリは 8GB です。大きなモデルでは量子化 (bitsandbytes) を使用してください"
echo "  - vLLM は一部の CUDA バージョンで非互換の場合があります"
echo ""
