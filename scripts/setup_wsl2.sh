#!/bin/bash
# =============================================================================
# WSL2 Ubuntu 22.04 環境構築スクリプト
# =============================================================================
#
# 概要:
#   WSL2 上の Ubuntu 22.04 に開発に必要な基本パッケージをインストールし、
#   開発環境を構築するスクリプト。Physical AI 学習プロジェクト用。
#
# 対象マシン:
#   - Intel Core Ultra 9 275HX / 32GB RAM / RTX 5070 (8GB VRAM)
#   - WSL2 Ubuntu 22.04
#
# 使い方:
#   chmod +x setup_wsl2.sh
#   ./setup_wsl2.sh
#
# 注意:
#   - sudo 権限が必要です
#   - 冪等性あり（何度実行しても安全）
#   - Windows 側で Git を使う場合、実行権限が保持されないことがあります
#     その場合は WSL2 内で chmod +x setup_wsl2.sh を実行してください
# =============================================================================

set -euo pipefail

# --- 色定義 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
# スクリプトがエラーで終了した場合にクリーンアップ処理を行う
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "スクリプトがエラーで終了しました (exit code: $exit_code)"
        log_error "エラーが発生した行: ${BASH_LINENO[0]}"
        log_error "ログを確認して問題を修正してから再実行してください"
    fi
}
trap cleanup EXIT

# --- パッケージインストール済み確認関数 ---
# dpkg でパッケージがインストール済みか確認する
is_pkg_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# コマンドが存在するか確認する
is_cmd_available() {
    command -v "$1" &>/dev/null
}

# --- メイン処理開始 ---
log_step "WSL2 Ubuntu 22.04 環境構築を開始します"

# Ubuntu 22.04 であることを確認する
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$VERSION_ID" != "22.04" ]; then
        log_warn "Ubuntu 22.04 以外のバージョンが検出されました: $VERSION_ID"
        log_warn "このスクリプトは Ubuntu 22.04 向けに設計されています"
        read -rp "続行しますか？ (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log_info "中止しました"
            exit 0
        fi
    fi
else
    log_warn "/etc/os-release が見つかりません。Ubuntu であることを確認できません"
fi

# =============================================================================
# Step 1: システムアップデート
# =============================================================================
log_step "Step 1: システムアップデート (apt update && apt upgrade)"

log_info "パッケージリストを更新します..."
sudo apt-get update -y

log_info "インストール済みパッケージをアップグレードします..."
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log_success "システムアップデート完了"

# =============================================================================
# Step 2: 必須ビルドツールのインストール
# =============================================================================
log_step "Step 2: 必須ビルドツールのインストール"

# インストールするパッケージリスト
BUILD_TOOLS=(
    build-essential  # GCC, G++, make 等のコンパイルツール一式
    cmake            # クロスプラットフォームビルドシステム
    git              # バージョン管理システム
    curl             # URL からのデータ転送ツール
    wget             # ファイルダウンロードツール
    unzip            # ZIP ファイル解凍ツール
    software-properties-common  # PPA リポジトリ管理ツール
    pkg-config       # ライブラリのコンパイルフラグ管理
    gdb              # GNU デバッガ
    ninja-build      # 高速ビルドシステム (CMake のバックエンド)
)

# 未インストールのパッケージのみをフィルタリングする
PKGS_TO_INSTALL=()
for pkg in "${BUILD_TOOLS[@]}"; do
    if is_pkg_installed "$pkg"; then
        log_info "  [済] $pkg は既にインストール済み"
    else
        PKGS_TO_INSTALL+=("$pkg")
        log_info "  [未] $pkg をインストールします"
    fi
done

if [ ${#PKGS_TO_INSTALL[@]} -gt 0 ]; then
    sudo apt-get install -y "${PKGS_TO_INSTALL[@]}"
    log_success "ビルドツールのインストール完了"
else
    log_success "全てのビルドツールは既にインストール済みです"
fi

# =============================================================================
# Step 3: 開発ライブラリのインストール
# =============================================================================
log_step "Step 3: 開発ライブラリのインストール"

DEV_LIBS=(
    libssl-dev        # OpenSSL 開発用ヘッダ
    libffi-dev        # Foreign Function Interface ライブラリ
    python3-dev       # Python 3 開発用ヘッダ
    python3-pip       # Python パッケージマネージャ
    python3-venv      # Python 仮想環境サポート
    libxml2-dev       # XML パーサー開発用
    libxslt1-dev      # XSLT プロセッサ開発用
    libyaml-dev       # YAML パーサー開発用
    libcurl4-openssl-dev  # cURL 開発用ライブラリ
    zlib1g-dev        # 圧縮ライブラリ開発用
    libbz2-dev        # bzip2 圧縮ライブラリ開発用
    libreadline-dev   # コマンドライン編集ライブラリ
    libsqlite3-dev    # SQLite3 開発用
    liblzma-dev       # LZMA 圧縮ライブラリ
    libncurses5-dev   # ターミナル制御ライブラリ
    tk-dev            # Tkinter (Python GUI) 開発用
    libopenblas-dev   # 線形代数演算ライブラリ (NumPy/SciPy 高速化)
    liblapack-dev     # LAPACK 線形代数ライブラリ
    libeigen3-dev     # Eigen C++ 線形代数テンプレートライブラリ
)

PKGS_TO_INSTALL=()
for pkg in "${DEV_LIBS[@]}"; do
    if is_pkg_installed "$pkg"; then
        log_info "  [済] $pkg は既にインストール済み"
    else
        PKGS_TO_INSTALL+=("$pkg")
        log_info "  [未] $pkg をインストールします"
    fi
done

if [ ${#PKGS_TO_INSTALL[@]} -gt 0 ]; then
    sudo apt-get install -y "${PKGS_TO_INSTALL[@]}"
    log_success "開発ライブラリのインストール完了"
else
    log_success "全ての開発ライブラリは既にインストール済みです"
fi

# =============================================================================
# Step 4: GUI サポートパッケージのインストール (WSLg)
# =============================================================================
log_step "Step 4: GUI サポートパッケージ (WSLg) のインストール"

# WSLg は Windows 11 + WSL2 で Linux GUI アプリをネイティブに実行可能にする機能
GUI_PKGS=(
    x11-apps        # xeyes, xclock 等の基本 X11 テストアプリ
    mesa-utils      # glxinfo, glxgears 等の OpenGL テストツール
    libgl1-mesa-dev # OpenGL 開発用ライブラリ
    libglu1-mesa-dev  # GLU (OpenGL Utility) ライブラリ
    libxrandr-dev   # X11 RandR 拡張開発用
    libxinerama-dev # X11 Xinerama 拡張開発用
    libxcursor-dev  # X11 カーソルライブラリ
    libxi-dev       # X11 Input 拡張開発用
    libxext-dev     # X11 拡張ライブラリ
    libxrender-dev  # X11 Render 拡張開発用
    libx11-dev      # X11 基本開発用ライブラリ
    xdg-utils       # デスクトップ統合ユーティリティ
)

PKGS_TO_INSTALL=()
for pkg in "${GUI_PKGS[@]}"; do
    if is_pkg_installed "$pkg"; then
        log_info "  [済] $pkg は既にインストール済み"
    else
        PKGS_TO_INSTALL+=("$pkg")
        log_info "  [未] $pkg をインストールします"
    fi
done

if [ ${#PKGS_TO_INSTALL[@]} -gt 0 ]; then
    sudo apt-get install -y "${PKGS_TO_INSTALL[@]}"
    log_success "GUI サポートパッケージのインストール完了"
else
    log_success "全ての GUI サポートパッケージは既にインストール済みです"
fi

# =============================================================================
# Step 5: 便利な開発ツールのインストール
# =============================================================================
log_step "Step 5: 便利な開発ツールのインストール"

DEV_TOOLS=(
    htop      # インタラクティブなプロセスビューア (top の高機能版)
    tmux      # ターミナルマルチプレクサ (複数セッション管理)
    tree      # ディレクトリ構造をツリー表示
    jq        # JSON プロセッサ (コマンドラインで JSON 操作)
    ripgrep   # 高速な grep 代替 (rg コマンド)
    fd-find   # 高速な find 代替 (fdfind コマンド)
    bat       # cat の高機能版 (シンタックスハイライト付き)
    ncdu      # ディスク使用量分析ツール
    neofetch  # システム情報表示ツール
    net-tools # ifconfig, netstat 等のネットワークツール
    iproute2  # ip コマンド等の最新ネットワークツール
    dnsutils  # nslookup, dig 等の DNS ツール
    openssh-client  # SSH クライアント
)

PKGS_TO_INSTALL=()
for pkg in "${DEV_TOOLS[@]}"; do
    if is_pkg_installed "$pkg"; then
        log_info "  [済] $pkg は既にインストール済み"
    else
        PKGS_TO_INSTALL+=("$pkg")
        log_info "  [未] $pkg をインストールします"
    fi
done

if [ ${#PKGS_TO_INSTALL[@]} -gt 0 ]; then
    sudo apt-get install -y "${PKGS_TO_INSTALL[@]}"
    log_success "開発ツールのインストール完了"
else
    log_success "全ての開発ツールは既にインストール済みです"
fi

# =============================================================================
# Step 6: ロケール設定
# =============================================================================
log_step "Step 6: ロケール設定 (en_US.UTF-8 / ja_JP.UTF-8)"

# ロケール生成に必要なパッケージをインストール
if ! is_pkg_installed "locales"; then
    sudo apt-get install -y locales
fi

# en_US.UTF-8 ロケールを生成（メイン言語）
if locale -a 2>/dev/null | grep -q "en_US.utf8"; then
    log_info "en_US.UTF-8 ロケールは既に生成済みです"
else
    log_info "en_US.UTF-8 ロケールを生成します..."
    sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sudo locale-gen en_US.UTF-8
    log_success "en_US.UTF-8 ロケール生成完了"
fi

# ja_JP.UTF-8 ロケールを生成（日本語サポート用）
if locale -a 2>/dev/null | grep -q "ja_JP.utf8"; then
    log_info "ja_JP.UTF-8 ロケールは既に生成済みです"
else
    log_info "ja_JP.UTF-8 ロケールを生成します..."
    sudo sed -i 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen
    sudo locale-gen ja_JP.UTF-8
    log_success "ja_JP.UTF-8 ロケール生成完了"
fi

# デフォルトロケールを en_US.UTF-8 に設定
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

log_success "ロケール設定完了"

# =============================================================================
# Step 7: .bashrc のカスタマイズ
# =============================================================================
log_step "Step 7: .bashrc のカスタマイズ"

BASHRC="$HOME/.bashrc"
MARKER="# === Physical AI Learning Project Setup ==="

# 既に追加済みかどうかマーカーで判定する（冪等性の確保）
if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    log_warn ".bashrc のカスタマイズは既に適用済みです。スキップします"
else
    log_info ".bashrc にカスタム設定を追加します..."

    cat >> "$BASHRC" << 'BASHRC_ADDITIONS'

# === Physical AI Learning Project Setup ===
# このセクションは setup_wsl2.sh によって自動追加されました

# --- カラープロンプト設定 ---
# ユーザー名@ホスト名を緑、カレントディレクトリを青で表示
export PS1='\[\033[01;32m\]\u@\w\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '

# --- 便利なエイリアス ---
alias ll='ls -alF --color=auto'       # 詳細リスト表示
alias la='ls -A --color=auto'         # 隠しファイル含むリスト
alias l='ls -CF --color=auto'         # コンパクトリスト
alias ..='cd ..'                      # 一つ上のディレクトリ
alias ...='cd ../..'                  # 二つ上のディレクトリ
alias grep='grep --color=auto'        # grep に色付け
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'                     # 履歴表示
alias cls='clear'                     # 画面クリア
alias ports='netstat -tulanp'         # ポート一覧表示
alias df='df -h'                      # ディスク使用量 (人間可読形式)
alias du='du -h'                      # ディレクトリサイズ (人間可読形式)
alias free='free -h'                  # メモリ使用量 (人間可読形式)

# fd-find は Ubuntu では fdfind という名前でインストールされる
if command -v fdfind &>/dev/null; then
    alias fd='fdfind'
fi

# bat は Ubuntu では batcat という名前でインストールされる
if command -v batcat &>/dev/null; then
    alias bat='batcat'
fi

# --- GPU 関連のエイリアス ---
alias gpu='nvidia-smi'                # GPU 状態確認
alias gpu-watch='watch -n 1 nvidia-smi'  # GPU 状態監視 (1秒更新)

# --- PATH 追加 ---
# ローカルバイナリパスを追加（pip install --user 等で使用）
export PATH="$HOME/.local/bin:$PATH"

# --- エディタ設定 ---
export EDITOR=vim
export VISUAL=vim

# --- 履歴設定 ---
export HISTSIZE=10000          # メモリ上の履歴数
export HISTFILESIZE=20000      # ファイルに保存する履歴数
export HISTCONTROL=ignoredups:erasedups  # 重複を無視
shopt -s histappend            # 履歴を上書きではなく追記

# --- その他の便利な設定 ---
shopt -s checkwinsize          # ウィンドウサイズ変更を自動検出
shopt -s globstar              # ** でサブディレクトリ再帰マッチ

# === End Physical AI Learning Project Setup ===
BASHRC_ADDITIONS

    log_success ".bashrc のカスタマイズ完了"
fi

# =============================================================================
# Step 8: WSLg 動作確認
# =============================================================================
log_step "Step 8: WSLg 動作確認"

# DISPLAY 環境変数の確認
if [ -n "${DISPLAY:-}" ]; then
    log_success "DISPLAY 環境変数が設定されています: $DISPLAY"
else
    log_warn "DISPLAY 環境変数が設定されていません"
    log_warn "WSLg が有効な場合、新しいターミナルセッションで自動設定されます"
fi

# WAYLAND_DISPLAY の確認（WSLg は Wayland ベース）
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    log_success "WAYLAND_DISPLAY が設定されています: $WAYLAND_DISPLAY"
else
    log_info "WAYLAND_DISPLAY が未設定です（X11 フォールバックを使用する可能性があります）"
fi

# WSLg ソケットの存在確認
if [ -e "/mnt/wslg/runtime-dir/wayland-0" ] || [ -d "/mnt/wslg" ]; then
    log_success "WSLg のランタイムディレクトリが検出されました"
    log_info "GUI アプリのテスト: 以下のコマンドで確認できます"
    log_info "  xclock  (時計アプリ)"
    log_info "  xeyes   (目玉アプリ)"
    log_info "  glxgears (OpenGL テスト)"
else
    log_warn "WSLg のランタイムディレクトリが見つかりません"
    log_warn "Windows 11 と最新の WSL2 が必要です"
    log_warn "PowerShell で 'wsl --update' を実行してみてください"
fi

# =============================================================================
# Step 9: インストール結果サマリー
# =============================================================================
log_step "Step 9: インストール結果サマリー"

echo ""
echo -e "${GREEN}=== インストール済みツールのバージョン ===${NC}"
echo ""

# 各ツールのバージョンを表示する関数
show_version() {
    local cmd="$1"
    local version_flag="${2:---version}"
    if is_cmd_available "$cmd"; then
        local ver
        ver=$($cmd $version_flag 2>&1 | head -n 1)
        echo -e "  ${GREEN}[OK]${NC} $cmd: $ver"
    else
        echo -e "  ${RED}[NG]${NC} $cmd: 見つかりません"
    fi
}

show_version gcc
show_version g++
show_version cmake
show_version git
show_version python3
show_version pip3
show_version make
show_version ninja "--version"
show_version curl
show_version wget
show_version tmux "-V"
show_version rg
show_version jq
show_version htop

echo ""
echo -e "${GREEN}=== ロケール設定 ===${NC}"
locale 2>/dev/null | head -3 || log_warn "ロケール情報を取得できません（再ログイン後に反映されます）"

echo ""
echo -e "${GREEN}=== ディスク使用量 ===${NC}"
df -h / | tail -1

echo ""
echo -e "${GREEN}=== メモリ情報 ===${NC}"
free -h | head -2

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}  WSL2 環境構築が完了しました！${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  1. ターミナルを再起動するか 'source ~/.bashrc' を実行してください"
echo "  2. scripts/setup_cuda_wsl2.sh を実行して CUDA をセットアップ"
echo "  3. scripts/setup_ros2.sh を実行して ROS 2 をインストール"
echo "  4. scripts/setup_python_env.sh を実行して Python 環境を構築"
echo ""
