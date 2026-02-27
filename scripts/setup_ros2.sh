#!/bin/bash
# =============================================================================
# ROS 2 Humble Hawksbill インストールスクリプト
# =============================================================================
#
# 概要:
#   WSL2 Ubuntu 22.04 に ROS 2 Humble Desktop Full をインストールし、
#   Physical AI 開発に必要な追加パッケージも導入するスクリプト。
#
# 対象マシン:
#   - Intel Core Ultra 9 275HX / 32GB RAM / RTX 5070 (8GB VRAM)
#   - WSL2 Ubuntu 22.04
#
# 前提条件:
#   - setup_wsl2.sh が実行済みであること
#
# 使い方:
#   chmod +x setup_ros2.sh
#   ./setup_ros2.sh
#
# 注意:
#   - sudo 権限が必要です
#   - インストールに 2-5GB のディスク容量が必要です
#   - ネットワーク接続が必要です
#   - 冪等性あり（何度実行しても安全）
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
        log_error "ROS 2 のインストールが不完全な可能性があります"
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
# Step 1: Ubuntu バージョンの確認
# =============================================================================
log_step "Step 1: Ubuntu バージョンの確認"

# ROS 2 Humble は Ubuntu 22.04 (Jammy Jellyfish) 専用
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$VERSION_ID" = "22.04" ]; then
        log_success "Ubuntu 22.04 ($VERSION_CODENAME) を確認しました"
    else
        log_error "Ubuntu 22.04 が必要です。検出されたバージョン: $VERSION_ID"
        log_error "ROS 2 Humble は Ubuntu 22.04 (Jammy) のみをサポートしています"
        exit 1
    fi
else
    log_error "/etc/os-release が見つかりません"
    exit 1
fi

# =============================================================================
# Step 2: ロケール設定の確認
# =============================================================================
log_step "Step 2: ロケール設定 (UTF-8)"

# ROS 2 は UTF-8 ロケールを必要とする
if locale 2>/dev/null | grep -q "UTF-8"; then
    log_success "UTF-8 ロケールが設定されています"
else
    log_info "UTF-8 ロケールを設定します..."
    sudo apt-get update -y && sudo apt-get install -y locales
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
    log_success "UTF-8 ロケール設定完了"
fi

# =============================================================================
# Step 3: ROS 2 apt リポジトリの追加
# =============================================================================
log_step "Step 3: ROS 2 apt リポジトリの追加"

# 必要なツールのインストール
log_info "curl と gnupg をインストールします..."
sudo apt-get install -y curl gnupg lsb-release

# ROS 2 GPG キーの追加
ROS_KEYRING="/usr/share/keyrings/ros-archive-keyring.gpg"
if [ -f "$ROS_KEYRING" ]; then
    log_info "ROS 2 GPG キーは既に存在します"
else
    log_info "ROS 2 GPG キーを追加します..."
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o "$ROS_KEYRING"
    log_success "ROS 2 GPG キー追加完了"
fi

# ROS 2 リポジトリの追加
ROS_SOURCES="/etc/apt/sources.list.d/ros2.list"
if [ -f "$ROS_SOURCES" ]; then
    log_info "ROS 2 リポジトリは既に追加されています"
else
    log_info "ROS 2 リポジトリを追加します..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$ROS_KEYRING] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") main" | \
        sudo tee "$ROS_SOURCES" > /dev/null
    log_success "ROS 2 リポジトリ追加完了"
fi

# パッケージリストを更新
log_info "パッケージリストを更新します..."
sudo apt-get update -y

# =============================================================================
# Step 4: ROS 2 Humble Desktop Full のインストール
# =============================================================================
log_step "Step 4: ROS 2 Humble Desktop Full のインストール"

# Desktop Full には以下が含まれる:
#   - ROS 2 コアライブラリ
#   - RViz2 (3D 可視化ツール)
#   - デモノード
#   - 開発ツール
if is_pkg_installed "ros-humble-desktop-full"; then
    log_success "ros-humble-desktop-full は既にインストール済みです"
else
    log_info "ROS 2 Humble Desktop Full をインストールします..."
    log_info "これには数分かかる場合があります..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ros-humble-desktop-full
    log_success "ROS 2 Humble Desktop Full インストール完了"
fi

# =============================================================================
# Step 5: 追加 ROS 2 パッケージのインストール
# =============================================================================
log_step "Step 5: 追加 ROS 2 パッケージのインストール"

# Physical AI 開発に必要な追加パッケージ
ROS_PKGS=(
    # --- Gazebo Classic 連携 ---
    ros-humble-gazebo-ros-pkgs         # Gazebo Classic と ROS 2 のブリッジ

    # --- Navigation2 (自律ナビゲーション) ---
    ros-humble-navigation2             # Nav2 コア
    ros-humble-nav2-bringup            # Nav2 起動設定ファイル

    # --- SLAM (同時位置推定と地図構築) ---
    ros-humble-slam-toolbox            # SLAM Toolbox (2D LiDAR SLAM)

    # --- ロボットモデル関連 ---
    ros-humble-robot-state-publisher   # ロボットの TF ツリーを publish
    ros-humble-joint-state-publisher-gui  # ジョイント状態を GUI で操作
    ros-humble-xacro                   # URDF マクロプロセッサ

    # --- ros2_control (ハードウェアインタフェース) ---
    ros-humble-ros2-control            # ロボット制御フレームワーク
    ros-humble-ros2-controllers        # 標準コントローラ群

    # --- 可視化・デバッグ ---
    ros-humble-rviz2                   # 3D 可視化ツール
    ros-humble-tf2-tools               # TF ツリーのデバッグツール
    ros-humble-rqt                     # Qt ベースの GUI フレームワーク
    ros-humble-rqt-common-plugins      # rqt 標準プラグイン群

    # --- RMW (ミドルウェア) ---
    ros-humble-rmw-cyclonedds-cpp      # CycloneDDS ミドルウェア実装
)

PKGS_TO_INSTALL=()
for pkg in "${ROS_PKGS[@]}"; do
    if is_pkg_installed "$pkg"; then
        log_info "  [済] $pkg"
    else
        PKGS_TO_INSTALL+=("$pkg")
        log_info "  [未] $pkg をインストールします"
    fi
done

if [ ${#PKGS_TO_INSTALL[@]} -gt 0 ]; then
    log_info "追加パッケージをインストールしています..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PKGS_TO_INSTALL[@]}"
    log_success "追加 ROS 2 パッケージインストール完了"
else
    log_success "全ての追加パッケージは既にインストール済みです"
fi

# Gazebo Sim (Ignition/Gz) ブリッジのインストール（利用可能な場合）
log_info "ros-humble-ros-gz (Gazebo Sim ブリッジ) の確認..."
if is_pkg_installed "ros-humble-ros-gz"; then
    log_success "ros-humble-ros-gz は既にインストール済みです"
elif apt-cache show ros-humble-ros-gz &>/dev/null 2>&1; then
    log_info "ros-humble-ros-gz をインストールします..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ros-humble-ros-gz || {
        log_warn "ros-humble-ros-gz のインストールに失敗しました"
        log_warn "Gazebo Sim (Ignition) ブリッジは後で手動インストールが必要かもしれません"
    }
else
    log_warn "ros-humble-ros-gz はリポジトリに見つかりません"
    log_warn "Gazebo Sim ブリッジが必要な場合は、ソースからビルドが必要です"
fi

# =============================================================================
# Step 6: 開発ツールのインストール
# =============================================================================
log_step "Step 6: ROS 2 開発ツールのインストール"

ROS_DEV_TOOLS=(
    python3-colcon-common-extensions  # colcon ビルドツール
    python3-rosdep                    # ROS 依存関係管理ツール
    python3-vcstool                   # VCS ツール (リポジトリ管理)
    python3-argcomplete               # コマンド引数の自動補完
    python3-colcon-mixin              # colcon ミックスイン (ビルド設定プリセット)
    python3-rosinstall-generator      # rosinstall ファイル生成ツール
)

PKGS_TO_INSTALL=()
for pkg in "${ROS_DEV_TOOLS[@]}"; do
    if is_pkg_installed "$pkg"; then
        log_info "  [済] $pkg"
    else
        PKGS_TO_INSTALL+=("$pkg")
        log_info "  [未] $pkg をインストールします"
    fi
done

if [ ${#PKGS_TO_INSTALL[@]} -gt 0 ]; then
    sudo apt-get install -y "${PKGS_TO_INSTALL[@]}"
    log_success "ROS 2 開発ツールインストール完了"
else
    log_success "全ての開発ツールは既にインストール済みです"
fi

# =============================================================================
# Step 7: rosdep の初期化
# =============================================================================
log_step "Step 7: rosdep の初期化"

# rosdep はパッケージの依存関係を自動解決するツール
if [ -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
    log_info "rosdep は既に初期化済みです"
else
    log_info "rosdep を初期化します..."
    sudo rosdep init || {
        log_warn "rosdep init が失敗しました（既に初期化済みの可能性があります）"
    }
fi

log_info "rosdep データベースを更新します..."
rosdep update --rosdistro=humble || {
    log_warn "rosdep update で警告がありました"
}
log_success "rosdep 初期化完了"

# =============================================================================
# Step 8: .bashrc への ROS 2 設定追加
# =============================================================================
log_step "Step 8: .bashrc への ROS 2 設定追加"

BASHRC="$HOME/.bashrc"
MARKER="# === ROS 2 Humble Setup ==="

if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    log_warn "ROS 2 の .bashrc 設定は既に追加済みです。スキップします"
else
    log_info ".bashrc に ROS 2 設定を追加します..."

    cat >> "$BASHRC" << 'BASHRC_ROS2'

# === ROS 2 Humble Setup ===
# このセクションは setup_ros2.sh によって自動追加されました

# ROS 2 Humble 環境のセットアップスクリプトを読み込む
source /opt/ros/humble/setup.bash

# colcon のコマンド補完を有効化
if [ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash ]; then
    source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
fi

# ROS 2 ワークスペースのセットアップ (ビルド後に有効)
if [ -f "$HOME/ros2_ws/install/setup.bash" ]; then
    source "$HOME/ros2_ws/install/setup.bash"
fi

# ROS_DOMAIN_ID: 同じネットワーク上の複数の ROS 2 システムを分離する ID
# 同じ ID を持つノード同士のみ通信可能（0-232 の範囲）
export ROS_DOMAIN_ID=0

# RMW_IMPLEMENTATION: DDS ミドルウェアの実装を指定
# CycloneDDS は WSL2 環境での互換性が高い
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# ROS 2 ログレベル設定（必要に応じてコメント解除）
# export RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity} {time}] [{name}]: {message}"
# export RCUTILS_COLORIZED_OUTPUT=1

# --- ROS 2 便利エイリアス ---
alias ros2-list-nodes='ros2 node list'
alias ros2-list-topics='ros2 topic list'
alias ros2-list-services='ros2 service list'
alias ros2-list-params='ros2 param list'

# colcon ビルドのエイリアス
alias cb='cd ~/ros2_ws && colcon build --symlink-install'
alias cbs='cd ~/ros2_ws && colcon build --symlink-install --packages-select'
alias cs='source ~/ros2_ws/install/setup.bash'

# === End ROS 2 Humble Setup ===
BASHRC_ROS2

    log_success ".bashrc への ROS 2 設定追加完了"
fi

# =============================================================================
# Step 9: ROS 2 ワークスペースの作成
# =============================================================================
log_step "Step 9: ROS 2 ワークスペースの作成"

ROS2_WS="$HOME/ros2_ws"

if [ -d "$ROS2_WS/src" ]; then
    log_info "ROS 2 ワークスペース ($ROS2_WS) は既に存在します"
else
    log_info "ROS 2 ワークスペースを作成します: $ROS2_WS"
    mkdir -p "$ROS2_WS/src"
    log_success "ワークスペース作成完了: $ROS2_WS/src"
fi

# ワークスペースをビルドして初期化
log_info "ワークスペースを初期ビルドします..."
# ROS 2 環境を読み込んでからビルド
# shellcheck source=/dev/null
source /opt/ros/humble/setup.bash
cd "$ROS2_WS"
colcon build --symlink-install 2>/dev/null || {
    log_info "ワークスペースが空のため、初期ビルドはスキップされました（正常）"
}
cd - > /dev/null

log_success "ROS 2 ワークスペース準備完了"

# =============================================================================
# Step 10: インストールの検証
# =============================================================================
log_step "Step 10: インストールの検証"

# ROS 2 環境を読み込む
# shellcheck source=/dev/null
source /opt/ros/humble/setup.bash

# ROS 2 バージョン確認
log_info "ROS 2 バージョンを確認します..."
if is_cmd_available "ros2"; then
    ROS2_VER=$(ros2 --version 2>/dev/null || echo "バージョン取得失敗")
    log_success "ros2 CLI: $ROS2_VER"
else
    log_error "ros2 コマンドが見つかりません"
    exit 1
fi

# ROS 2 ディストリビューション確認
log_info "ROS_DISTRO: ${ROS_DISTRO:-未設定}"

# パッケージ一覧の確認
log_info "インストール済み ROS 2 パッケージ数を確認..."
PKG_COUNT=$(ros2 pkg list 2>/dev/null | wc -l)
log_success "インストール済みパッケージ数: $PKG_COUNT"

# talker/listener のテスト
log_info "talker/listener の通信テストを実行します..."
log_info "（5秒間のテスト後、自動終了します）"

# バックグラウンドで talker を起動
ros2 run demo_nodes_cpp talker &>/dev/null &
TALKER_PID=$!

# 少し待ってから listener を起動してメッセージを受信
sleep 2
LISTENER_OUTPUT=$(timeout 5 ros2 run demo_nodes_cpp listener 2>/dev/null || true)

# テストプロセスをクリーンアップ
kill $TALKER_PID 2>/dev/null || true
wait $TALKER_PID 2>/dev/null || true

if echo "$LISTENER_OUTPUT" | grep -q "Hello World"; then
    log_success "talker/listener テスト成功！ ROS 2 は正常に動作しています"
else
    log_warn "talker/listener テストでメッセージを確認できませんでした"
    log_warn "これは WSL2 環境の DDS 設定に依存する場合があります"
    log_info "手動テスト: ターミナル1で 'ros2 run demo_nodes_cpp talker'"
    log_info "            ターミナル2で 'ros2 run demo_nodes_cpp listener'"
fi

# =============================================================================
# Step 11: サマリー表示
# =============================================================================
log_step "Step 11: インストールサマリー"

echo ""
echo -e "${GREEN}=== ROS 2 Humble インストール結果 ===${NC}"
echo ""
echo -e "  ROS 2 ディストリビューション: ${GREEN}Humble Hawksbill${NC}"
echo -e "  インストールタイプ:           ${GREEN}Desktop Full${NC}"
echo -e "  パッケージ数:                 ${GREEN}$PKG_COUNT${NC}"
echo -e "  ワークスペース:               ${GREEN}$ROS2_WS${NC}"
echo -e "  RMW 実装:                     ${GREEN}CycloneDDS${NC}"
echo -e "  ROS_DOMAIN_ID:                ${GREEN}0${NC}"
echo ""

echo -e "${GREEN}=== インストール済み主要パッケージ ===${NC}"
echo ""
# 主要パッケージの確認
MAJOR_PKGS=(
    "ros-humble-desktop-full:ROS 2 Desktop Full"
    "ros-humble-navigation2:Navigation2"
    "ros-humble-slam-toolbox:SLAM Toolbox"
    "ros-humble-gazebo-ros-pkgs:Gazebo Integration"
    "ros-humble-ros2-control:ros2_control"
    "ros-humble-rmw-cyclonedds-cpp:CycloneDDS"
)
for entry in "${MAJOR_PKGS[@]}"; do
    pkg="${entry%%:*}"
    desc="${entry##*:}"
    if is_pkg_installed "$pkg"; then
        echo -e "  ${GREEN}[OK]${NC} $desc ($pkg)"
    else
        echo -e "  ${YELLOW}[--]${NC} $desc ($pkg) - 未インストール"
    fi
done

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}  ROS 2 Humble のインストールが完了しました！${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  1. 'source ~/.bashrc' を実行するか、ターミナルを再起動してください"
echo "  2. 'ros2 run demo_nodes_cpp talker' で動作確認"
echo "  3. ~/ros2_ws/src にパッケージを作成して開発を開始"
echo ""
echo -e "${YELLOW}よく使うコマンド:${NC}"
echo "  ros2 pkg list          - パッケージ一覧"
echo "  ros2 topic list        - トピック一覧"
echo "  ros2 node list         - ノード一覧"
echo "  ros2 run <pkg> <node>  - ノードの実行"
echo "  ros2 launch <pkg> <launch_file>  - Launch ファイルの実行"
echo "  cb                     - ワークスペースのビルド (エイリアス)"
echo ""
