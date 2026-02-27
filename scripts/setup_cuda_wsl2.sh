#!/bin/bash
# =============================================================================
# CUDA on WSL2 セットアップスクリプト
# =============================================================================
#
# 概要:
#   WSL2 Ubuntu 22.04 に CUDA Toolkit、cuDNN、TensorRT をインストールし、
#   GPU アクセラレーション環境を構築するスクリプト。
#
# 対象マシン:
#   - Intel Core Ultra 9 275HX / 32GB RAM / RTX 5070 (8GB VRAM)
#   - WSL2 Ubuntu 22.04
#   - Windows 側に GeForce ドライバ（560.x 以降推奨）がインストール済み
#
# 重要:
#   - WSL2 内に NVIDIA ドライバをインストールしないでください
#   - ドライバは Windows 側からのパススルーで提供されます
#   - CUDA Toolkit のみを WSL2 内にインストールします
#
# 前提条件:
#   - setup_wsl2.sh が実行済みであること
#   - Windows 側に最新の GeForce ドライバがインストール済みであること
#
# 使い方:
#   chmod +x setup_cuda_wsl2.sh
#   ./setup_cuda_wsl2.sh
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
        log_error "CUDA のインストールが不完全な可能性があります"
        log_error "エラーを修正してから再実行してください"
    fi
}
trap cleanup EXIT

# --- ユーティリティ関数 ---
is_pkg_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

is_cmd_available() {
    command -v "$1" &>/dev/null
}

# =============================================================================
# CUDA バージョン設定
# =============================================================================
# RTX 5070 (Blackwell アーキテクチャ) をサポートするバージョン
CUDA_VERSION="12-6"
CUDA_VERSION_DOT="12.6"
CUDNN_VERSION="9"

# =============================================================================
# Step 1: WSL2 環境であることの確認
# =============================================================================
log_step "Step 1: WSL2 環境の確認"

# WSL2 環境の検出方法:
# 1. /proc/version に Microsoft/WSL が含まれる
# 2. WSL_DISTRO_NAME 環境変数が設定されている
if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
    log_success "WSL2 環境を確認しました"
elif [ -n "${WSL_DISTRO_NAME:-}" ]; then
    log_success "WSL2 環境を確認しました (distro: $WSL_DISTRO_NAME)"
else
    log_error "WSL2 環境が検出されませんでした"
    log_error "このスクリプトは WSL2 専用です"
    exit 1
fi

# WSL バージョンの確認（WSL2 であること）
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    log_success "WSL interop が有効です"
else
    log_warn "WSL interop の確認ができませんでした"
fi

# =============================================================================
# Step 2: NVIDIA GPU アクセスの確認
# =============================================================================
log_step "Step 2: NVIDIA GPU アクセスの確認"

# nvidia-smi は Windows 側のドライバから WSL2 にパススルーされる
if is_cmd_available "nvidia-smi"; then
    log_success "nvidia-smi が利用可能です"
    echo ""
    nvidia-smi
    echo ""

    # GPU 名の取得
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "不明")
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "不明")
    CUDA_DRIVER_VER=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 || echo "不明")

    log_success "GPU: $GPU_NAME"
    log_success "ドライババージョン: $DRIVER_VERSION"
else
    log_error "nvidia-smi が見つかりません"
    log_error "Windows 側に NVIDIA GeForce ドライバがインストールされていることを確認してください"
    log_error "インストール手順:"
    log_error "  1. https://www.nvidia.com/download/index.aspx から最新ドライバをダウンロード"
    log_error "  2. ドライバインストール後、WSL2 を再起動: wsl --shutdown"
    exit 1
fi

# =============================================================================
# Step 3: Windows ドライバの確認
# =============================================================================
log_step "Step 3: Windows 側ドライバの確認"

log_info "Windows 側の GeForce ドライバが GPU アクセスを提供します"
log_info "WSL2 内に NVIDIA ドライバをインストールする必要はありません"

# libcuda.so の確認（Windows ドライバから提供される）
if [ -e "/usr/lib/wsl/lib/libcuda.so" ] || [ -e "/usr/lib/wsl/lib/libcuda.so.1" ]; then
    log_success "WSL2 用 CUDA ライブラリ (libcuda.so) が検出されました"
else
    log_warn "WSL2 用 CUDA ライブラリが標準パスに見つかりません"
    log_warn "ドライバのバージョンによってはパスが異なる場合があります"
fi

# =============================================================================
# Step 4: 既存の競合パッケージの確認と削除
# =============================================================================
log_step "Step 4: 競合パッケージの確認"

# WSL2 では nvidia-driver パッケージをインストールしてはいけない
# （Windows 側のドライバと競合する）
CONFLICTING_PKGS=(
    nvidia-driver-*
    nvidia-dkms-*
    nvidia-utils-*
)

FOUND_CONFLICTS=false
for pattern in "${CONFLICTING_PKGS[@]}"; do
    # dpkg でパターンマッチ
    if dpkg -l $pattern 2>/dev/null | grep -q "^ii"; then
        log_warn "競合パッケージが検出されました: $pattern"
        FOUND_CONFLICTS=true
    fi
done

if [ "$FOUND_CONFLICTS" = true ]; then
    log_warn "WSL2 内に NVIDIA ドライバパッケージがインストールされています"
    log_warn "これは Windows 側のドライバと競合する可能性があります"
    read -rp "競合パッケージを削除しますか？ (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        sudo apt-get remove --purge -y nvidia-driver-* nvidia-dkms-* nvidia-utils-* 2>/dev/null || true
        sudo apt-get autoremove -y
        log_success "競合パッケージを削除しました"
    else
        log_warn "競合パッケージが残っています。問題が発生する可能性があります"
    fi
else
    log_success "競合パッケージは検出されませんでした"
fi

# =============================================================================
# Step 5: CUDA Toolkit のインストール
# =============================================================================
log_step "Step 5: CUDA Toolkit ${CUDA_VERSION_DOT} のインストール"

# 既に CUDA Toolkit がインストール済みかチェック
if is_cmd_available "nvcc"; then
    CURRENT_NVCC_VER=$(nvcc --version 2>/dev/null | grep "release" | sed 's/.*release //' | sed 's/,.*//')
    log_info "既存の CUDA Toolkit が検出されました: $CURRENT_NVCC_VER"
    log_info "CUDA Toolkit の再インストールをスキップします"
    CUDA_ALREADY_INSTALLED=true
else
    CUDA_ALREADY_INSTALLED=false
fi

if [ "$CUDA_ALREADY_INSTALLED" = false ]; then
    # NVIDIA CUDA リポジトリ用のキーリングパッケージをインストール
    log_info "NVIDIA CUDA リポジトリを追加します..."

    # WSL-Ubuntu 用の CUDA リポジトリ pin ファイル
    CUDA_PIN_URL="https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin"
    if [ ! -f /etc/apt/preferences.d/cuda-repository-pin-600 ]; then
        wget -q "$CUDA_PIN_URL" -O /tmp/cuda-wsl-ubuntu.pin
        sudo mv /tmp/cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
        log_success "CUDA リポジトリの pin ファイルを設定しました"
    fi

    # CUDA リポジトリ GPG キーとリポジトリの追加
    CUDA_KEYRING_PKG="cuda-keyring_1.1-1_all.deb"
    CUDA_KEYRING_URL="https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/${CUDA_KEYRING_PKG}"

    if ! is_pkg_installed "cuda-keyring"; then
        log_info "CUDA キーリングパッケージをインストールします..."
        wget -q "$CUDA_KEYRING_URL" -O "/tmp/${CUDA_KEYRING_PKG}"
        sudo dpkg -i "/tmp/${CUDA_KEYRING_PKG}"
        rm -f "/tmp/${CUDA_KEYRING_PKG}"
        log_success "CUDA キーリングインストール完了"
    else
        log_info "CUDA キーリングは既にインストール済みです"
    fi

    # パッケージリストを更新
    sudo apt-get update -y

    # CUDA Toolkit のみをインストール（ドライバは含めない）
    # 重要: "cuda" パッケージではなく "cuda-toolkit" を使用
    # "cuda" パッケージにはドライバが含まれ、WSL2 で問題を起こす
    log_info "CUDA Toolkit ${CUDA_VERSION_DOT} をインストールします..."
    log_info "これには数分かかる場合があります..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "cuda-toolkit-${CUDA_VERSION}"

    log_success "CUDA Toolkit ${CUDA_VERSION_DOT} インストール完了"
fi

# =============================================================================
# Step 6: cuDNN のインストール
# =============================================================================
log_step "Step 6: cuDNN のインストール"

# cuDNN はディープラーニングの畳み込み演算を高速化するライブラリ
CUDNN_PKG="libcudnn${CUDNN_VERSION}-cuda-${CUDA_VERSION%%.*}"

if is_pkg_installed "$CUDNN_PKG" || is_pkg_installed "libcudnn${CUDNN_VERSION}-dev-cuda-${CUDA_VERSION%%.*}"; then
    log_info "cuDNN は既にインストール済みです"
else
    log_info "cuDNN をインストールします..."

    # cuDNN パッケージの検索とインストール
    # CUDA リポジトリから利用可能なバージョンを確認
    if apt-cache show "libcudnn${CUDNN_VERSION}-cuda-${CUDA_VERSION%%.*}" &>/dev/null 2>&1; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            "libcudnn${CUDNN_VERSION}-cuda-${CUDA_VERSION%%.*}" \
            "libcudnn${CUDNN_VERSION}-dev-cuda-${CUDA_VERSION%%.*}" || {
            log_warn "cuDNN ${CUDNN_VERSION} のインストールに失敗しました"
            log_info "代替パッケージ名で再試行します..."

            # 代替パッケージ名でのインストール試行
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
                libcudnn9-cuda-12 libcudnn9-dev-cuda-12 2>/dev/null || {
                log_warn "cuDNN の自動インストールに失敗しました"
                log_warn "手動でインストールが必要な場合があります"
                log_warn "参考: https://developer.nvidia.com/cudnn"
            }
        }
    else
        log_info "利用可能な cuDNN パッケージを検索します..."
        AVAILABLE_CUDNN=$(apt-cache search "libcudnn" 2>/dev/null | head -10 || true)
        if [ -n "$AVAILABLE_CUDNN" ]; then
            log_info "利用可能な cuDNN パッケージ:"
            echo "$AVAILABLE_CUDNN"
            # 最新の cuDNN パッケージを自動選択してインストール
            CUDNN_INSTALL_PKG=$(apt-cache search "libcudnn.*-dev-cuda-12" 2>/dev/null | head -1 | awk '{print $1}' || true)
            if [ -n "$CUDNN_INSTALL_PKG" ]; then
                log_info "  $CUDNN_INSTALL_PKG をインストールします..."
                CUDNN_BASE_PKG=$(echo "$CUDNN_INSTALL_PKG" | sed 's/-dev//')
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
                    "$CUDNN_BASE_PKG" "$CUDNN_INSTALL_PKG" || {
                    log_warn "cuDNN のインストールに失敗しました"
                }
            fi
        else
            log_warn "cuDNN パッケージが見つかりません"
            log_warn "CUDA リポジトリが正しく設定されているか確認してください"
        fi
    fi
fi

log_success "cuDNN セットアップ完了"

# =============================================================================
# Step 7: 環境変数の設定
# =============================================================================
log_step "Step 7: 環境変数の設定"

BASHRC="$HOME/.bashrc"
MARKER="# === CUDA Environment Setup ==="

if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    log_warn "CUDA 環境変数は既に .bashrc に設定済みです。スキップします"
else
    log_info "CUDA 環境変数を .bashrc に追加します..."

    cat >> "$BASHRC" << 'BASHRC_CUDA'

# === CUDA Environment Setup ===
# このセクションは setup_cuda_wsl2.sh によって自動追加されました

# CUDA Toolkit のパス設定
export CUDA_HOME=/usr/local/cuda
export PATH="${CUDA_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH:-}"

# WSL2 の NVIDIA ライブラリパスを追加
# Windows 側のドライバから提供される libcuda.so 等
if [ -d "/usr/lib/wsl/lib" ]; then
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}"
fi

# cuDNN ライブラリパスの追加（インストールされている場合）
if [ -d "/usr/lib/x86_64-linux-gnu" ]; then
    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
fi

# CUDA デバイスの設定
# 複数 GPU がある場合、使用する GPU を指定（0 = 最初の GPU）
# export CUDA_VISIBLE_DEVICES=0

# === End CUDA Environment Setup ===
BASHRC_CUDA

    log_success "CUDA 環境変数の設定完了"
fi

# 現在のセッションに環境変数を適用
export CUDA_HOME=/usr/local/cuda
export PATH="${CUDA_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH:-}"
if [ -d "/usr/lib/wsl/lib" ]; then
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}"
fi

# =============================================================================
# Step 8: TensorRT のインストール（オプション）
# =============================================================================
log_step "Step 8: TensorRT のインストール（オプション）"

# TensorRT は推論を最適化・高速化するライブラリ
# モデルのデプロイ時に使用する
log_info "TensorRT のインストールを確認します..."

if is_pkg_installed "libnvinfer-dev" || is_pkg_installed "tensorrt"; then
    log_info "TensorRT は既にインストール済みです"
else
    log_info "TensorRT のインストールを試みます..."

    # CUDA リポジトリから TensorRT を検索
    TENSORRT_AVAILABLE=$(apt-cache search "tensorrt" 2>/dev/null | head -5 || true)
    NVINFER_AVAILABLE=$(apt-cache search "libnvinfer" 2>/dev/null | grep -i "dev" | head -5 || true)

    if [ -n "$NVINFER_AVAILABLE" ]; then
        log_info "利用可能な TensorRT パッケージ:"
        echo "$NVINFER_AVAILABLE"

        # libnvinfer-dev のインストールを試みる
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            libnvinfer-dev libnvinfer-plugin-dev 2>/dev/null || {
            log_warn "TensorRT のインストールに失敗しました"
            log_info "TensorRT は以下の方法で手動インストールできます:"
            log_info "  1. https://developer.nvidia.com/tensorrt から DEB パッケージをダウンロード"
            log_info "  2. sudo dpkg -i <パッケージ名>.deb"
            log_info "  3. sudo apt-get install -f"
        }
    elif [ -n "$TENSORRT_AVAILABLE" ]; then
        log_info "TensorRT メタパッケージのインストールを試みます..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tensorrt 2>/dev/null || {
            log_warn "TensorRT メタパッケージのインストールに失敗しました"
        }
    else
        log_warn "TensorRT パッケージがリポジトリに見つかりません"
        log_info "TensorRT は NVIDIA Developer サイトから手動ダウンロードが必要な場合があります"
        log_info "  https://developer.nvidia.com/tensorrt"
        log_info "  後から pip install tensorrt でも Python バインディングをインストールできます"
    fi
fi

log_success "TensorRT セットアップ完了"

# =============================================================================
# Step 9: インストールの検証
# =============================================================================
log_step "Step 9: インストールの検証"

echo ""
VERIFICATION_PASSED=true

# nvidia-smi の確認
log_info "=== nvidia-smi ==="
if nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=name,driver_version,memory.total,memory.free,compute_cap \
        --format=csv,noheader 2>/dev/null | while IFS=',' read -r name driver mem_total mem_free compute; do
        echo -e "  ${GREEN}GPU:${NC}             $name"
        echo -e "  ${GREEN}ドライバ:${NC}        $driver"
        echo -e "  ${GREEN}VRAM 合計:${NC}       $mem_total"
        echo -e "  ${GREEN}VRAM 空き:${NC}       $mem_free"
        echo -e "  ${GREEN}Compute Cap:${NC}     $compute"
    done
    log_success "nvidia-smi: OK"
else
    log_error "nvidia-smi: 失敗"
    VERIFICATION_PASSED=false
fi

echo ""

# nvcc の確認
log_info "=== nvcc (CUDA Compiler) ==="
if is_cmd_available "nvcc"; then
    nvcc --version 2>/dev/null | tail -3
    log_success "nvcc: OK"
else
    log_error "nvcc が見つかりません"
    log_info "パスが正しく設定されていない可能性があります"
    log_info "/usr/local/cuda/bin/nvcc の存在を確認してください"
    VERIFICATION_PASSED=false
fi

echo ""

# CUDA サンプルのコンパイルテスト
log_info "=== CUDA コンパイルテスト ==="
CUDA_TEST_DIR=$(mktemp -d)
CUDA_TEST_FILE="$CUDA_TEST_DIR/test_cuda.cu"

# 簡単な CUDA プログラムを作成してコンパイルテスト
cat > "$CUDA_TEST_FILE" << 'CUDA_TEST'
#include <stdio.h>
#include <cuda_runtime.h>

__global__ void hello_kernel() {
    printf("Hello from GPU thread %d in block %d!\n", threadIdx.x, blockIdx.x);
}

int main() {
    int deviceCount = 0;
    cudaError_t error = cudaGetDeviceCount(&deviceCount);

    if (error != cudaSuccess) {
        printf("CUDA Error: %s\n", cudaGetErrorString(error));
        return 1;
    }

    printf("CUDA Device Count: %d\n", deviceCount);

    for (int i = 0; i < deviceCount; i++) {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        printf("Device %d: %s\n", i, prop.name);
        printf("  Compute Capability: %d.%d\n", prop.major, prop.minor);
        printf("  Total Global Memory: %.1f GB\n", prop.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
        printf("  Multiprocessors: %d\n", prop.multiProcessorCount);
        printf("  Max Threads per Block: %d\n", prop.maxThreadsPerBlock);
    }

    // カーネルを1ブロック、4スレッドで実行
    hello_kernel<<<1, 4>>>();
    cudaDeviceSynchronize();

    printf("CUDA test completed successfully!\n");
    return 0;
}
CUDA_TEST

if is_cmd_available "nvcc"; then
    if nvcc -o "$CUDA_TEST_DIR/test_cuda" "$CUDA_TEST_FILE" 2>/dev/null; then
        log_success "CUDA プログラムのコンパイル: OK"
        if "$CUDA_TEST_DIR/test_cuda" 2>/dev/null; then
            log_success "CUDA プログラムの実行: OK"
        else
            log_warn "CUDA プログラムの実行に失敗しました（GPU アクセスの問題の可能性）"
        fi
    else
        log_warn "CUDA プログラムのコンパイルに失敗しました"
    fi
else
    log_warn "nvcc が利用できないためコンパイルテストをスキップ"
fi

# テンポラリファイルのクリーンアップ
rm -rf "$CUDA_TEST_DIR"

echo ""

# Python での CUDA 確認（PyTorch がインストールされている場合）
log_info "=== Python CUDA テスト ==="
if is_cmd_available "python3"; then
    python3 -c "
try:
    import torch
    print(f'  PyTorch version: {torch.__version__}')
    print(f'  CUDA available: {torch.cuda.is_available()}')
    if torch.cuda.is_available():
        print(f'  CUDA version: {torch.version.cuda}')
        print(f'  GPU: {torch.cuda.get_device_name(0)}')
        print(f'  VRAM: {torch.cuda.get_device_properties(0).total_mem / 1024**3:.1f} GB')
except ImportError:
    print('  PyTorch はまだインストールされていません')
    print('  setup_python_env.sh を実行して PyTorch をインストールしてください')
" 2>/dev/null || log_info "Python CUDA テストをスキップ（PyTorch 未インストール）"
else
    log_warn "Python3 が見つかりません"
fi

# =============================================================================
# Step 10: サマリー表示
# =============================================================================
log_step "Step 10: インストールサマリー"

echo ""
echo -e "${GREEN}=== CUDA on WSL2 セットアップ結果 ===${NC}"
echo ""

# 各コンポーネントの状態
echo -e "  ${GREEN}[GPU]${NC}"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1 | \
    awk -F',' '{printf "    名前: %s\n    VRAM: %s\n", $1, $2}'

echo ""
echo -e "  ${GREEN}[CUDA Toolkit]${NC}"
if is_cmd_available "nvcc"; then
    NVCC_VER=$(nvcc --version 2>/dev/null | grep "release" | sed 's/.*release //' | sed 's/,.*//')
    echo "    バージョン: $NVCC_VER"
    echo "    パス: $(which nvcc)"
else
    echo -e "    ${RED}未インストール${NC}"
fi

echo ""
echo -e "  ${GREEN}[cuDNN]${NC}"
CUDNN_H="/usr/include/cudnn_version.h"
if [ -f "$CUDNN_H" ]; then
    CUDNN_MAJOR=$(grep "#define CUDNN_MAJOR" "$CUDNN_H" 2>/dev/null | awk '{print $3}' || echo "?")
    CUDNN_MINOR=$(grep "#define CUDNN_MINOR" "$CUDNN_H" 2>/dev/null | awk '{print $3}' || echo "?")
    CUDNN_PATCH=$(grep "#define CUDNN_PATCHLEVEL" "$CUDNN_H" 2>/dev/null | awk '{print $3}' || echo "?")
    echo "    バージョン: ${CUDNN_MAJOR}.${CUDNN_MINOR}.${CUDNN_PATCH}"
else
    # 代替チェック
    if dpkg -l 2>/dev/null | grep -q "libcudnn"; then
        CUDNN_PKG_VER=$(dpkg -l 2>/dev/null | grep "libcudnn" | head -1 | awk '{print $3}')
        echo "    バージョン: $CUDNN_PKG_VER (パッケージ版)"
    else
        echo -e "    ${YELLOW}インストール状態不明${NC}"
    fi
fi

echo ""
echo -e "  ${GREEN}[TensorRT]${NC}"
if is_pkg_installed "libnvinfer-dev" || is_pkg_installed "tensorrt"; then
    echo "    インストール済み"
else
    echo -e "    ${YELLOW}未インストール（オプション）${NC}"
fi

echo ""
echo -e "  ${GREEN}[環境変数]${NC}"
echo "    CUDA_HOME=${CUDA_HOME:-未設定}"
echo "    PATH に cuda/bin: $(echo "$PATH" | grep -q "cuda/bin" && echo "含まれている" || echo "含まれていない")"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}  CUDA on WSL2 セットアップが完了しました！${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  1. 'source ~/.bashrc' を実行するか、ターミナルを再起動してください"
echo "  2. 'nvidia-smi' で GPU 状態を確認"
echo "  3. 'nvcc --version' で CUDA コンパイラを確認"
echo "  4. scripts/setup_python_env.sh を実行して PyTorch をインストール"
echo ""
echo -e "${YELLOW}トラブルシューティング:${NC}"
echo "  - nvidia-smi が動かない: Windows 側の GeForce ドライバを最新に更新"
echo "  - nvcc が見つからない: source ~/.bashrc を実行"
echo "  - CUDA out of memory: GPU メモリ 8GB の制限に注意"
echo "  - WSL2 を再起動: PowerShell で 'wsl --shutdown' を実行"
echo ""
