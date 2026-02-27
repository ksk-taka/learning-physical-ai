# Physical AI 学習環境 セットアップガイド

## 目次

- [概要](#概要)
- [前提条件](#前提条件)
- [1. WSL2 セットアップ](#1-wsl2-セットアップ)
- [2. ROS 2 Humble インストール](#2-ros-2-humble-インストール)
- [3. CUDA on WSL2](#3-cuda-on-wsl2)
- [4. Python 環境](#4-python-環境)
- [5. Gazebo インストール](#5-gazebo-インストール)
- [6. ROS 2 開発ツール](#6-ros-2-開発ツール)
- [7. VS Code Remote WSL](#7-vs-code-remote-wsl)
- [8. Isaac Sim (Windows)](#8-isaac-sim-windows)
- [9. Git 設定](#9-git-設定)
- [10. 全体動作確認](#10-全体動作確認)

---

## 概要

本ドキュメントは、Physical AI 学習のための開発環境を構築する手順を記載する。
全てのコマンドはコピー＆ペーストで実行可能な形式で記述している。

**想定所要時間**: 4〜6 時間（ダウンロード時間を含む）

**構成図**:

```
┌─────────────────────────────────────────────────┐
│ Windows 11 (Host)                                │
│                                                   │
│  ┌─────────────────┐    ┌─────────────────────┐  │
│  │ NVIDIA Driver    │    │ Isaac Sim            │  │
│  │ (GeForce)        │    │ (Omniverse)          │  │
│  │ VS Code          │    │                       │  │
│  └────────┬────────┘    └──────────────────────┘  │
│           │                                        │
│  ┌────────▼──────────────────────────────────┐    │
│  │ WSL2 + Ubuntu 22.04                        │    │
│  │                                             │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │    │
│  │  │ ROS 2    │  │ CUDA     │  │ Python   │ │    │
│  │  │ Humble   │  │ Toolkit  │  │ Conda    │ │    │
│  │  ├──────────┤  ├──────────┤  ├──────────┤ │    │
│  │  │ Gazebo   │  │ cuDNN    │  │ PyTorch  │ │    │
│  │  │ Nav2     │  │ TensorRT │  │ VLM      │ │    │
│  │  │ SLAM     │  │          │  │ Whisper  │ │    │
│  │  └──────────┘  └──────────┘  └──────────┘ │    │
│  └────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

---

## 前提条件

| 項目 | 要件 |
|------|------|
| OS | Windows 11 Home/Pro (22H2 以降推奨) |
| GPU | NVIDIA RTX 5070 (8GB VRAM) |
| RAM | 32GB 以上推奨（最低 16GB） |
| ストレージ | SSD 100GB 以上の空き容量 |
| インターネット | 安定した接続（大量ダウンロードあり） |

**事前準備**:
- 最新の Windows Update を適用済み
- 最新の NVIDIA GeForce ドライバーをインストール済み

---

## 1. WSL2 セットアップ

### 1.1 WSL2 のインストール

Windows PowerShell を **管理者として実行** する。

```powershell
# WSL2 と Ubuntu 22.04 をインストール
wsl --install -d Ubuntu-22.04
```

インストール完了後、PC を再起動する。
再起動後、Ubuntu のターミナルが自動で開くので、ユーザー名とパスワードを設定する。

```powershell
# インストール確認
wsl --list --verbose

# 期待される出力:
#   NAME            STATE           VERSION
# * Ubuntu-22.04    Running         2
```

### 1.2 WSL のアップデート

```powershell
wsl --update
wsl --version
# WSL バージョンが 1.0.0 以上であることを確認
```

### 1.3 .wslconfig の設定

Windows 側で `C:\Users\<ユーザー名>\.wslconfig` を作成する。

```powershell
notepad "$env:USERPROFILE\.wslconfig"
```

以下の内容を記述して保存する。

```ini
[wsl2]
memory=16GB
processors=10
swap=8GB
nestedVirtualization=true

[experimental]
sparseVhd=true
```

設定を反映する。

```powershell
wsl --shutdown
wsl
```

### 1.4 WSLg (GUI) の確認

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y x11-apps

# テスト（ウィンドウが表示されれば成功）
xclock &
xeyes &
```

### 1.5 X11 フォワーディング（WSLg が動かない場合の代替）

VcXsrv (https://sourceforge.net/projects/vcxsrv/) をインストールし、XLaunch で起動する。
設定: Multiple windows → Start no client → **Disable access control にチェック**

```bash
# ~/.bashrc に追記
cat << 'EOF' >> ~/.bashrc

# X11 forwarding (VcXsrv)
if [ -z "$WAYLAND_DISPLAY" ]; then
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
    export LIBGL_ALWAYS_INDIRECT=0
fi
EOF

source ~/.bashrc
```

### 1.6 基本パッケージのインストール

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    build-essential cmake git curl wget vim nano htop tree unzip \
    software-properties-common apt-transport-https ca-certificates \
    gnupg lsb-release locales

sudo locale-gen en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

### トラブルシューティング: WSL2

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `wsl --install` が失敗 | 仮想化が無効 | BIOS で Intel VT-x / AMD-V を有効化 |
| 起動が遅い | メモリ不足 | `.wslconfig` でメモリを調整 |
| ネットワーク接続不可 | DNS 設定の問題 | 下記の DNS 修正を参照 |
| WSLg で画面が真っ暗 | ドライバの問題 | NVIDIA ドライバを最新に更新 |
| ディスク容量増大 | VHD 未圧縮 | `.wslconfig` で `sparseVhd=true` |

**DNS 問題の修正**:

```bash
sudo bash -c 'cat > /etc/wsl.conf << EOF
[network]
generateResolvConf = false
EOF'

sudo rm /etc/resolv.conf
sudo bash -c 'cat > /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF'
# PowerShell で wsl --shutdown 後に再起動
```

---

## 2. ROS 2 Humble インストール

### 2.1 リポジトリの追加

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository universe

# ROS 2 GPG キーの追加
sudo apt update && sudo apt install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg

# ROS 2 リポジトリの追加
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
| sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update && sudo apt upgrade -y
```

### 2.2 ROS 2 Humble のインストール

```bash
# フルデスクトップ版（rviz2, rqt 等含む）
sudo apt install -y ros-humble-desktop

# 開発ツール
sudo apt install -y ros-dev-tools
```

**10〜20 分程度かかる。**

### 2.3 環境変数の設定

```bash
cat << 'EOF' >> ~/.bashrc

# === ROS 2 Humble 環境設定 ===
source /opt/ros/humble/setup.bash
export ROS_DOMAIN_ID=42
export RCUTILS_COLORIZED_OUTPUT=1
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

if [ -f ~/ros2_ws/install/setup.bash ]; then
    source ~/ros2_ws/install/setup.bash
fi
EOF

source ~/.bashrc
```

### 2.4 動作確認

**ターミナル 1**:

```bash
ros2 run demo_nodes_cpp talker
# [INFO] [talker]: Publishing: 'Hello World: 1'
```

**ターミナル 2**:

```bash
ros2 run demo_nodes_cpp listener
# [INFO] [listener]: I heard: [Hello World: 1]
```

### 2.5 GUI ツールの確認

```bash
rqt &
rviz2 &
ros2 run turtlesim turtlesim_node &
ros2 run turtlesim turtle_teleop_key
```

turtlesim のウィンドウが表示され、矢印キーで亀を操作できれば成功。

### 2.6 追加パッケージのインストール

```bash
sudo apt install -y \
    ros-humble-turtlesim \
    ros-humble-tf2-tools ros-humble-tf2-ros ros-humble-tf2-geometry-msgs \
    ros-humble-teleop-twist-keyboard \
    ros-humble-joint-state-publisher-gui ros-humble-robot-state-publisher ros-humble-xacro \
    ros-humble-cv-bridge ros-humble-image-transport \
    ros-humble-rqt-graph ros-humble-rqt-topic ros-humble-rqt-service-caller ros-humble-rqt-console
```

### トラブルシューティング: ROS 2

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `ros2: command not found` | 環境変数未設定 | `source /opt/ros/humble/setup.bash` |
| `Package 'xxx' not found` | 未インストール | `sudo apt install ros-humble-xxx` |
| GUI が表示されない | WSLg の問題 | セクション 1.5 の X11 フォワーディングを参照 |
| ノード間で通信できない | ファイアウォール/DDS | 下記 DDS 切り替えを参照 |
| `ros2 topic list` が空 | DOMAIN_ID 不一致 | `ROS_DOMAIN_ID` が一致しているか確認 |

**DDS 実装の切り替え（通信問題の場合）**:

```bash
sudo apt install -y ros-humble-rmw-cyclonedds-cpp
echo 'export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp' >> ~/.bashrc
source ~/.bashrc
```

---

## 3. CUDA on WSL2

### 3.1 NVIDIA ドライバーの確認

**重要**: WSL2 では Windows 側の NVIDIA ドライバーを使用する。
WSL2 内に NVIDIA ドライバーをインストールしてはならない。

```bash
nvidia-smi
# RTX 5070 が認識され、CUDA Version が表示されることを確認
```

**動作しない場合**: Windows 側で最新の GeForce ドライバーをインストール → PC 再起動 → `wsl --shutdown`

### 3.2 CUDA Toolkit のインストール

```bash
# CUDA GPG キーの追加
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
rm cuda-keyring_1.1-1_all.deb

sudo apt update

# CUDA Toolkit のインストール（ドライバーは含めない）
sudo apt install -y cuda-toolkit-12-6
```

**注意**: `cuda-drivers` パッケージはインストールしないこと（Windows ドライバーと競合する）。

### 3.3 環境変数の設定

```bash
cat << 'EOF' >> ~/.bashrc

# === CUDA 環境設定 ===
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
EOF

source ~/.bashrc
```

### 3.4 動作確認

```bash
nvcc --version
# release 12.6 が表示されること

# GPU テスト（オプション）
git clone --depth 1 https://github.com/NVIDIA/cuda-samples.git
cd cuda-samples/Samples/1_Utilities/deviceQuery && make && ./deviceQuery
# Result = PASS と表示されれば成功
```

### 3.5 cuDNN のインストール

```bash
sudo apt install -y libcudnn9-cuda-12 libcudnn9-dev-cuda-12
```

### 3.6 TensorRT のインストール（オプション、Month 2 で必要時）

```bash
sudo apt install -y tensorrt
python3 -c "import tensorrt; print(tensorrt.__version__)"
```

### トラブルシューティング: CUDA

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `nvidia-smi` が動かない | ドライバー未認識 | Windows GeForce ドライバー更新後 WSL 再起動 |
| `nvcc: command not found` | PATH 未設定 | `export PATH=/usr/local/cuda/bin:$PATH` |
| `libcuda.so.1: cannot open` | ドライバーの問題 | `wsl --shutdown` 後に再起動 |
| `CUDA out of memory` | メモリ不足 | バッチサイズ削減、不要プロセス終了 |

**GPU メモリの確認と監視**:

```bash
watch -n 1 nvidia-smi
```

---

## 4. Python 環境

### 4.1 Miniconda のインストール

```bash
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
~/miniconda3/bin/conda init bash
source ~/.bashrc
```

### 4.2 conda 環境の作成

```bash
conda create -n physical-ai python=3.10 -y
conda activate physical-ai
```

### 4.3 PyTorch のインストール

```bash
conda activate physical-ai
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

**動作確認**:

```bash
python -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'GPU: {torch.cuda.get_device_name(0)}')
x = torch.randn(1000, 1000, device='cuda')
y = torch.matmul(x, x)
print(f'GPU computation OK: {y.shape}')
"
```

### 4.4 AI/ML パッケージのインストール

```bash
conda activate physical-ai

# Hugging Face Transformers + 量子化
pip install transformers accelerate bitsandbytes

# GPTQ / AWQ 量子化
pip install auto-gptq --extra-index-url https://huggingface.github.io/autogptq-index/whl/cu124/
pip install autoawq

# llama.cpp Python バインディング
pip install llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu124

# vLLM（推論サーバー）
pip install vllm

# ONNX Runtime GPU
pip install onnxruntime-gpu
```

### 4.5 コンピュータビジョン・音声認識パッケージ

```bash
conda activate physical-ai

# CV
pip install opencv-python opencv-python-headless open3d Pillow matplotlib

# 音声認識
sudo apt install -y portaudio19-dev
pip install faster-whisper pyaudio soundfile
```

### 4.6 その他ユーティリティ

```bash
conda activate physical-ai
pip install jupyter jupyterlab numpy pandas scipy tqdm pyyaml python-dotenv tensorboard
pip install gymnasium stable-baselines3
```

### 4.7 ROS 2 との連携用スクリプト

conda 環境と ROS 2 の Python が競合する場合があるため、切り替えスクリプトを用意する。

```bash
mkdir -p ~/scripts

# ROS 2 のみ
cat << 'SCRIPT' > ~/scripts/activate_ros2.sh
#!/bin/bash
conda deactivate 2>/dev/null
source /opt/ros/humble/setup.bash
[ -f ~/ros2_ws/install/setup.bash ] && source ~/ros2_ws/install/setup.bash
echo "ROS 2 environment activated."
SCRIPT

# AI + ROS 2
cat << 'SCRIPT' > ~/scripts/activate_ai.sh
#!/bin/bash
source /opt/ros/humble/setup.bash
[ -f ~/ros2_ws/install/setup.bash ] && source ~/ros2_ws/install/setup.bash
conda activate physical-ai
echo "AI + ROS 2 environment activated."
SCRIPT

chmod +x ~/scripts/activate_ros2.sh ~/scripts/activate_ai.sh
```

```bash
# 使い方
source ~/scripts/activate_ros2.sh    # ROS 2 のみ
source ~/scripts/activate_ai.sh      # AI + ROS 2
```

### トラブルシューティング: Python 環境

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `ModuleNotFoundError` | 未インストール | `pip install <package>` |
| `CUDA out of memory` | VRAM 不足 | バッチサイズ削減、量子化 |
| `torch.cuda.is_available()` が False | CUDA 非対応 PyTorch | CUDA 対応版を再インストール |
| bitsandbytes エラー | CUDA バージョン不一致 | `pip install bitsandbytes --force-reinstall` |
| ROS 2 Python と conda 競合 | 環境パス問題 | 上記切り替えスクリプト使用 |

---

## 5. Gazebo インストール

### 5.1 Gazebo Sim (Ignition) のインストール

```bash
sudo apt install -y ros-humble-ros-gz
```

これにより Gazebo Sim, ros_gz_bridge, ros_gz_sim, ros_gz_image がインストールされる。

### 5.2 動作確認

```bash
ign gazebo shapes.sdf
# 3D ウィンドウに箱・球・円柱が表示されれば成功

ros2 launch ros_gz_sim gz_sim.launch.py gz_args:="shapes.sdf"
```

### 5.3 TurtleBot3 パッケージ

```bash
sudo apt install -y \
    ros-humble-turtlebot3-gazebo ros-humble-turtlebot3-navigation2 \
    ros-humble-turtlebot3-description ros-humble-turtlebot3-teleop ros-humble-turtlebot3-bringup

echo 'export TURTLEBOT3_MODEL=burger' >> ~/.bashrc
echo 'export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/humble/share/turtlebot3_gazebo/models' >> ~/.bashrc
source ~/.bashrc
```

**動作確認**:

```bash
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
# 別ターミナルで:
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

### 5.4 SLAM / Navigation パッケージ

```bash
sudo apt install -y ros-humble-slam-toolbox
sudo apt install -y ros-humble-navigation2 ros-humble-nav2-bringup
sudo apt install -y ros-humble-cartographer ros-humble-cartographer-ros
```

### トラブルシューティング: Gazebo

| 症状 | 原因 | 解決策 |
|------|------|--------|
| 真っ黒な画面 | GPU レンダリング問題 | `export LIBGL_ALWAYS_SOFTWARE=1` |
| クラッシュ | メモリ不足 | WSL メモリ割り当てを増やす |
| モデルダウンロード失敗 | ネットワーク問題 | プロキシ確認 / 手動ダウンロード |
| `ign gazebo` が見つからない | コマンド名の違い | `gz sim` を試す |
| TurtleBot3 モデル非表示 | モデルパス問題 | `GAZEBO_MODEL_PATH` を確認 |

---

## 6. ROS 2 開発ツール

### 6.1 ツールのインストール

```bash
sudo apt install -y python3-colcon-common-extensions python3-vcstool

# rosdep の初期化
sudo rosdep init
rosdep update
```

### 6.2 ワークスペースのセットアップ

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash
```

### 6.3 パッケージ作成

```bash
cd ~/ros2_ws/src

# Python パッケージ
ros2 pkg create --build-type ament_python my_first_pkg \
    --dependencies rclpy std_msgs geometry_msgs sensor_msgs

# C++ パッケージ
ros2 pkg create --build-type ament_cmake my_cpp_pkg \
    --dependencies rclcpp std_msgs geometry_msgs sensor_msgs
```

### 6.4 便利なエイリアス

```bash
cat << 'EOF' >> ~/.bashrc

# === ROS 2 エイリアス ===
alias cb='cd ~/ros2_ws && colcon build --symlink-install'
alias cbs='cd ~/ros2_ws && colcon build --symlink-install --packages-select'
alias si='source ~/ros2_ws/install/setup.bash'
alias rtl='ros2 topic list'
alias rte='ros2 topic echo'
alias rnl='ros2 node list'
alias rsl='ros2 service list'
EOF

source ~/.bashrc
```

### 6.5 ROS 2 コマンドチートシート

```bash
# トピック
ros2 topic list / echo / info / hz / bw / pub

# ノード
ros2 node list / info

# サービス
ros2 service list / type / call

# アクション
ros2 action list / send_goal

# パラメータ
ros2 param list / get / set

# インターフェース
ros2 interface list / show

# bag（データ記録）
ros2 bag record -a                    # 全トピック記録
ros2 bag record /topic1 /topic2       # 指定トピック
ros2 bag play bag_file                # 再生

# 診断
ros2 doctor
```

### トラブルシューティング: 開発ツール

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `colcon build` 失敗 | 依存関係不足 | `rosdep install --from-paths src --ignore-src -r -y` |
| ビルドが遅い | 並列数問題 | `colcon build --parallel-workers 4` |
| 変更が反映されない | キャッシュ | `colcon build --cmake-clean-cache` |
| パッケージが見つからない | source 忘れ | `source ~/ros2_ws/install/setup.bash` |

---

## 7. VS Code Remote WSL

### 7.1 必須拡張機能

| 拡張機能 | ID | 用途 |
|---------|-----|------|
| WSL | ms-vscode-remote.remote-wsl | WSL2 接続 |
| Python | ms-python.python | Python 開発 |
| C/C++ | ms-vscode.cpptools | C++ 開発 |
| CMake | ms-vscode.cmake-tools | CMake |
| ROS | ms-iot.vscode-ros | ROS 2 |
| XML | redhat.vscode-xml | URDF/SDF |
| YAML | redhat.vscode-yaml | 設定ファイル |
| GitLens | eamodio.gitlens | Git 拡張 |

**一括インストール（PowerShell）**:

```powershell
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension ms-python.python
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.cmake-tools
code --install-extension ms-iot.vscode-ros
code --install-extension redhat.vscode-xml
code --install-extension redhat.vscode-yaml
code --install-extension eamodio.gitlens
```

### 7.2 WSL2 への接続

```bash
code ~/ros2_ws
```

初回は VS Code Server が自動インストールされる。

### 7.3 ワークスペース設定

`.vscode/settings.json`:

```json
{
    "python.defaultInterpreterPath": "/home/${env:USER}/miniconda3/envs/physical-ai/bin/python",
    "python.analysis.typeCheckingMode": "basic",
    "C_Cpp.default.includePath": [
        "/opt/ros/humble/include/**",
        "${workspaceFolder}/**/include/**"
    ],
    "files.associations": {
        "*.launch.py": "python",
        "*.urdf": "xml", "*.xacro": "xml", "*.sdf": "xml",
        "*.msg": "plaintext", "*.srv": "plaintext", "*.action": "plaintext"
    },
    "editor.formatOnSave": true,
    "editor.rulers": [100],
    "search.exclude": {
        "**/build": true, "**/install": true, "**/log": true
    }
}
```

### 7.4 デバッグ設定

`.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: ROS 2 Node",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "env": {
                "PYTHONPATH": "/opt/ros/humble/lib/python3.10/site-packages:/opt/ros/humble/local/lib/python3.10/dist-packages"
            }
        }
    ]
}
```

### 7.5 タスク設定

`.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "colcon build",
            "type": "shell",
            "command": "cd ~/ros2_ws && colcon build --symlink-install",
            "group": { "kind": "build", "isDefault": true }
        },
        {
            "label": "colcon test",
            "type": "shell",
            "command": "cd ~/ros2_ws && colcon test && colcon test-result --verbose",
            "group": { "kind": "test", "isDefault": true }
        }
    ]
}
```

### トラブルシューティング: VS Code

| 症状 | 原因 | 解決策 |
|------|------|--------|
| WSL に接続できない | WSL 未起動 | `wsl` で起動 |
| Python インタープリタ不明 | パス設定問題 | settings.json で正しいパスを指定 |
| IntelliSense 不動作 | include パス不備 | `C_Cpp.default.includePath` 確認 |
| ROS 2 コマンド使えない | 環境変数未設定 | ターミナルで `source /opt/ros/humble/setup.bash` |

---

## 8. Isaac Sim (Windows)

### 8.1 システム要件

| 項目 | 最小要件 | 本環境 |
|------|---------|--------|
| GPU | RTX 2070 | RTX 5070 |
| VRAM | 8GB | 8GB（最小ライン） |
| RAM | 32GB | 要確認 |
| SSD 空き | 50GB | 要確認 |
| ドライバー | 525.xx+ | 最新 |

### 8.2 インストール手順

1. NVIDIA Omniverse 公式サイト (https://www.nvidia.com/en-us/omniverse/) から Launcher をダウンロード
2. NVIDIA アカウントでサインイン
3. Omniverse Launcher をインストール・起動
4. 「Exchange」タブで「Isaac Sim」を検索し「Install」
5. インストール完了まで待機（30〜60 分、SSD 推奨）

### 8.3 初回起動

1. Omniverse Launcher → 「Library」→「Isaac Sim」を起動
2. 初回はシェーダーコンパイルで数分かかる
3. 「Content」パネルからサンプルシーンを開いて確認

### 8.4 ROS 2 Bridge

Isaac Sim (Windows) と WSL2 上の ROS 2 を接続する。

**Isaac Sim 側**: Window → Extensions → 「ROS2 Bridge」を有効化

**WSL2 側**:

```bash
cat << 'EOF' > ~/cyclonedds.xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <Domain>
        <General>
            <DontRoute>true</DontRoute>
            <NetworkInterfaceAddress>auto</NetworkInterfaceAddress>
        </General>
        <Discovery>
            <ParticipantIndex>auto</ParticipantIndex>
        </Discovery>
    </Domain>
</CycloneDDS>
EOF

echo 'export CYCLONEDDS_URI=file://$HOME/cyclonedds.xml' >> ~/.bashrc
source ~/.bashrc
```

### 8.5 パフォーマンス設定（VRAM 8GB 向け）

- Rendering: Ray Tracing → Path Tracing（品質下がるが軽い）
- Resolution: 1280x720 に下げる
- Anti-aliasing: TAA（DLSS より軽い）
- リアルタイムレンダリングは必要時のみ有効化

### 8.6 参考リンク

| リソース | URL |
|---------|-----|
| Isaac Sim ドキュメント | https://docs.omniverse.nvidia.com/isaacsim/ |
| チュートリアル | https://docs.omniverse.nvidia.com/isaacsim/latest/tutorials/ |
| ROS 2 Bridge | https://docs.omniverse.nvidia.com/isaacsim/latest/ros2_tutorials/ |
| Omniverse フォーラム | https://forums.developer.nvidia.com/c/omniverse/ |

### トラブルシューティング: Isaac Sim

| 症状 | 原因 | 解決策 |
|------|------|--------|
| 起動が非常に遅い | 初回シェーダーコンパイル | 5〜10 分待つ |
| フレームレートが低い | VRAM 不足 | 上記パフォーマンス設定を適用 |
| ROS 2 Bridge 通信しない | ネットワーク | DDS 設定と Windows Firewall 確認 |
| クラッシュ | VRAM/ドライバー | ドライバー更新、シーン簡略化 |

---

## 9. Git 設定

### 9.1 ユーザー情報の設定

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global core.autocrlf input

git config --global --list
```

### 9.2 SSH キーの生成と登録

```bash
# SSH キー生成
ssh-keygen -t ed25519 -C "your.email@example.com"
# Enter を押してデフォルトパスに保存、パスフレーズを設定

# SSH エージェント起動
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 公開鍵を表示（この出力を GitHub に登録）
cat ~/.ssh/id_ed25519.pub
```

**GitHub への登録**: Settings → SSH and GPG keys → New SSH key → 公開鍵を貼り付け

```bash
# 接続確認
ssh -T git@github.com
# "Hi <username>! You've successfully authenticated" と表示されれば成功
```

### 9.3 SSH エージェント自動起動

```bash
cat << 'EOF' >> ~/.bashrc

# === SSH Agent 自動起動 ===
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
```

### 9.4 .gitignore の設定

```bash
cat << 'EOF' > ~/ros2_ws/.gitignore
# ROS 2
build/
install/
log/

# Python
__pycache__/
*.py[cod]
*.egg-info/
dist/

# AI モデル（サイズが大きいため）
*.bin
*.pt
*.pth
*.onnx
*.safetensors
*.gguf

# データ
*.bag
*.db3

# その他
.env
*.log
.DS_Store
Thumbs.db
EOF
```

### 9.5 便利な Git エイリアス

```bash
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.ci "commit"
git config --global alias.lg "log --oneline --graph --all --decorate"
```

### トラブルシューティング: Git

| 症状 | 原因 | 解決策 |
|------|------|--------|
| SSH 認証失敗 | キー未登録 | `ssh-add ~/.ssh/id_ed25519` |
| `Permission denied (publickey)` | GitHub にキー未登録 | セクション 9.2 を実行 |
| 大きなファイルのプッシュ失敗 | サイズ制限 | `.gitignore` にモデルファイルを追加 |

---

## 10. 全体動作確認

### 10.1 一括確認スクリプト

```bash
echo "=========================================="
echo "Physical AI 環境チェック"
echo "=========================================="
echo "--- OS ---"
lsb_release -a 2>/dev/null | grep Description
echo "--- GPU ---"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo "--- CUDA ---"
nvcc --version 2>/dev/null | grep "release" || echo "nvcc not found"
echo "--- ROS 2 ---"
ros2 --version 2>/dev/null || echo "ROS 2 not found"
echo "--- Python ---"
python3 --version
echo "--- Conda ---"
conda --version 2>/dev/null || echo "Conda not found"
echo "--- Git ---"
git --version
echo "--- PyTorch CUDA ---"
python3 -c "import torch; print(f'PyTorch {torch.__version__}, CUDA: {torch.cuda.is_available()}')" 2>/dev/null || echo "PyTorch not found"
echo "=========================================="
```

### 10.2 チェックリスト

| # | 項目 | 確認コマンド | 期待結果 |
|---|------|-------------|---------|
| 1 | WSL2 動作 | `wsl --list --verbose` | Ubuntu-22.04 が Running |
| 2 | WSLg GUI | `xclock` | 時計ウィンドウ表示 |
| 3 | GPU 認識 | `nvidia-smi` | RTX 5070 表示 |
| 4 | CUDA Toolkit | `nvcc --version` | 12.x 表示 |
| 5 | ROS 2 | `ros2 run demo_nodes_cpp talker` | メッセージ出力 |
| 6 | turtlesim | `ros2 run turtlesim turtlesim_node` | 亀ウィンドウ |
| 7 | rviz2 | `rviz2` | 3D ビュー表示 |
| 8 | Gazebo | `ign gazebo shapes.sdf` | 3D ワールド表示 |
| 9 | PyTorch | Python スクリプト | CUDA True |
| 10 | Git SSH | `ssh -T git@github.com` | 認証成功 |
| 11 | VS Code | `code .` | VS Code 起動 |
| 12 | colcon | `cd ~/ros2_ws && colcon build` | ビルド成功 |

全項目に問題がなければ環境構築は完了。
[ROADMAP.md](./ROADMAP.md) に従って学習を開始する。

---

## FAQ

**Q: ROS 2 ビルドが遅い**
A: `colcon build --parallel-workers 4` で並列数を制限。メモリ不足なら `.wslconfig` 調整。

**Q: Gazebo のフレームレートが低い**
A: `export LIBGL_ALWAYS_SOFTWARE=1` を試す。それでも遅ければシンプルワールドを使用。

**Q: conda 環境で ROS 2 コマンドが使えない**
A: `source ~/scripts/activate_ai.sh` で両方を有効化。

**Q: GPU メモリが足りない**
A: `nvidia-smi` で不要プロセスを確認・終了。モデルの量子化（INT4/INT8）を使用。

**Q: WSL2 と Windows 間のファイル共有**
A: WSL2 → Windows は `/mnt/c/`、Windows → WSL2 は `\\wsl$\Ubuntu-22.04\`。
開発作業は WSL2 ファイルシステム上で行うことを推奨（パフォーマンスのため）。
