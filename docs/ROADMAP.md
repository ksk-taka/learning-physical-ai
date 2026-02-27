# Physical AI 学習ロードマップ（3ヶ月集中プラン）

## 目次

- [概要](#概要)
- [学習者プロフィール](#学習者プロフィール)
- [開発環境](#開発環境)
- [全体スケジュール概要](#全体スケジュール概要)
- [Month 1: ROS 2 + ロボット基礎（Week 1〜4）](#month-1-ros-2--ロボット基礎week-14)
- [Month 2: AI x ロボット連携（Week 5〜8）](#month-2-ai-x-ロボット連携week-58)
- [Month 3: シミュレーション & ポートフォリオ（Week 9〜12）](#month-3-シミュレーション--ポートフォリオweek-912)
- [補足: 学習リソースまとめ](#補足-学習リソースまとめ)
- [補足: ファームウェアエンジニア向け Tips](#補足-ファームウェアエンジニア向け-tips)

---

## 概要

本ロードマップは、Physical AI（物理世界で動作する AI 搭載ロボットシステム）を体系的に学ぶための
3ヶ月間の週次学習計画である。ファームウェアエンジニアとしての豊富な経験（C/C++、回路設計、センサ）と
ローカル LLM デプロイの経験を活かし、ROS 2 を中心としたロボットソフトウェア開発と
AI 統合技術を習得することを目標とする。

### 最終ゴール

1. ROS 2 でロボットシステムを構築できるスキルの獲得
2. VLM（Vision-Language Model）をエッジで動作させる技術の習得
3. 「自然言語指示 → ロボット動作」の統合デモの完成
4. GitHub ポートフォリオとして公開可能な成果物の制作

### 学習方針

- **平日**: 2〜3 時間/日（仕事後の学習を想定）
- **週末**: 4〜5 時間/日（土日でまとまった作業）
- **週あたり合計**: 約 18〜23 時間
- **3ヶ月合計**: 約 216〜276 時間

---

## 学習者プロフィール

| 項目 | 詳細 |
|------|------|
| 職種 | ファームウェアエンジニア |
| 得意領域 | C/C++ プログラミング、回路設計、センサ制御 |
| AI 経験 | ローカル LLM デプロイ経験あり |
| Python 経験 | 基礎レベル（スクリプト記述程度は可能と想定） |
| ROS 経験 | 未経験（ゼロからスタート） |
| Linux 経験 | 組み込み Linux の使用経験あり |

### 強みの活用ポイント

- **C/C++ の知識**: ROS 2 の内部実装（rclcpp）の理解が速い。ノード間通信の仕組みが直感的にわかる
- **回路設計の知識**: センサのデータシート理解、I2C/SPI 通信の知識がセンサノード開発に直結
- **センサの知識**: IMU、LiDAR、カメラのデータ特性の理解が SLAM やセンサフュージョンの学習を加速
- **LLM デプロイ経験**: 量子化・推論最適化の概念を既に理解している

---

## 開発環境

| 項目 | スペック |
|------|---------|
| OS | Windows 11 Home |
| GPU | NVIDIA RTX 5070 (8GB VRAM) |
| 仮想環境 | WSL2 + Ubuntu 22.04 |
| エディタ | VS Code (Remote - WSL) |
| ROS バージョン | ROS 2 Humble Hawksbill (LTS) |
| シミュレータ | Gazebo Sim (Ignition) / NVIDIA Isaac Sim |
| Python | 3.10 (Ubuntu 22.04 デフォルト) + Miniconda |

### VRAM 8GB での制約と対策

| モデルサイズ | 量子化 | 推定 VRAM 使用量 | 実行可否 |
|-------------|--------|------------------|---------|
| 7B パラメータ | FP16 | ~14GB | 不可 |
| 7B パラメータ | INT4 (GPTQ/AWQ) | ~4GB | 可能 |
| 7B パラメータ | GGUF Q4_K_M | ~4.5GB | 可能 |
| 13B パラメータ | INT4 | ~7.5GB | ギリギリ可能 |
| Florence-2 (0.2B) | FP16 | ~1GB | 余裕で可能 |
| LLaVA-1.5-7B | INT4 | ~5GB | 可能 |

---

## 全体スケジュール概要

```
Month 1: ROS 2 + ロボット基礎
├── Week 1:  ROS 2 入門 - 環境構築と基本概念
├── Week 2:  ROS 2 通信パターン深掘りと turtlesim 実践
├── Week 3:  シミュレーション環境と URDF
└── Week 4:  SLAM と自律ナビゲーション

Month 2: AI x ロボット連携
├── Week 5:  マルチモーダル AI 概要とローカル推論
├── Week 6:  VLM パイプライン構築と最適化
├── Week 7:  ROS 2 + AI 統合パイプライン設計
└── Week 8:  統合デモ完成と最適化

Month 3: シミュレーション & ポートフォリオ
├── Week 9:  NVIDIA Isaac Sim 導入
├── Week 10: 強化学習とシミュレーション連携
├── Week 11: ポートフォリオ制作
└── Week 12: 仕上げと公開
```

---

# Month 1: ROS 2 + ロボット基礎（Week 1〜4）

---

## Week 1: ROS 2 入門 - 環境構築と基本概念

### 学習目標

- WSL2 + Ubuntu 22.04 上に ROS 2 Humble の開発環境を完成させる
- ROS 2 の基本アーキテクチャ（ノード、トピック、サービス）を理解する
- 最初の Publisher/Subscriber ノードを Python で記述して動作確認する

### 「完了」基準

- [ ] `ros2 run demo_nodes_cpp talker` と `listener` が正常に通信する
- [ ] `rqt_graph` でノードのトピック接続が可視化できる
- [ ] 自作の Python Publisher ノードが `/my_topic` にメッセージを publish できる
- [ ] `turtlesim_node` が WSLg 上でウィンドウ表示される

### 日次スケジュール

#### Day 1（月）: WSL2 環境構築 [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:30 | WSL2 の状態確認・Ubuntu 22.04 インストール |
| 0:30-1:00 | `.wslconfig` の設定（メモリ 16GB、CPU 10コア） |
| 1:00-1:30 | WSLg の GUI 動作確認（`xclock`, `xeyes`） |
| 1:30-2:00 | 基本パッケージのインストール（git, curl, vim 等） |
| 2:00-2:30 | VS Code Remote - WSL のセットアップ |

#### Day 2（火）: ROS 2 Humble インストール [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:45 | ROS 2 Humble の apt インストール |
| 0:45-1:15 | `~/.bashrc` への環境変数設定 |
| 1:15-1:45 | 動作確認: `ros2 run demo_nodes_cpp talker` / `listener` |
| 1:45-2:15 | `rqt`, `rviz2` の起動確認 |
| 2:15-2:30 | colcon ビルドシステムのインストール |

#### Day 3（水）: ROS 2 基本概念の学習 [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:45 | ROS 2 公式チュートリアル: ノードの理解 |
| 0:45-1:30 | トピック（Pub/Sub）の理解 |
| 1:30-2:00 | `ros2 topic list/echo/info` の使い方 |
| 2:00-2:30 | `ros2 node list/info` の使い方 |

**ROS 2 CLI チートシート**:

```bash
ros2 topic list                          # トピック一覧
ros2 topic echo /topic_name              # トピックの中身を表示
ros2 topic info /topic_name              # トピックの型・接続情報
ros2 topic hz /topic_name                # パブリッシュ頻度
ros2 node list                           # ノード一覧
ros2 node info /node_name                # ノードの詳細情報
ros2 interface show std_msgs/msg/String  # メッセージ型の定義確認
```

#### Day 4（木）: 初めての Python ノード作成 [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:30 | ROS 2 ワークスペース (`~/ros2_ws`) の作成 |
| 0:30-1:00 | Python パッケージの作成 (`ros2 pkg create`) |
| 1:00-1:45 | Publisher ノードの実装 |
| 1:45-2:15 | Subscriber ノードの実装 |
| 2:15-2:30 | `colcon build` とテスト実行 |

```bash
mkdir -p ~/ros2_ws/src && cd ~/ros2_ws/src
ros2 pkg create --build-type ament_python my_first_pkg --dependencies rclpy std_msgs
cd ~/ros2_ws && colcon build --packages-select my_first_pkg
source install/setup.bash
```

**Publisher サンプル**:

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class MyPublisher(Node):
    def __init__(self):
        super().__init__('my_publisher')
        self.publisher_ = self.create_publisher(String, 'my_topic', 10)
        self.timer = self.create_timer(0.5, self.timer_callback)
        self.count = 0

    def timer_callback(self):
        msg = String()
        msg.data = f'Hello ROS 2: {self.count}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.count += 1

def main(args=None):
    rclpy.init(args=args)
    node = MyPublisher()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
```

#### Day 5（金）: turtlesim 入門 [2h]

| 時間 | 内容 |
|------|------|
| 0:00-0:30 | turtlesim の起動と `turtle_teleop_key` の使用 |
| 0:30-1:00 | turtlesim のトピック構造を `rqt_graph` で確認 |
| 1:00-1:30 | `ros2 topic pub` でコマンドラインから亀を動かす |
| 1:30-2:00 | 振り返りと Week 1 後半の準備 |

```bash
ros2 run turtlesim turtlesim_node
ros2 run turtlesim turtle_teleop_key
ros2 topic pub /turtle1/cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
```

#### Day 6（土）: turtlesim カスタムノード [4.5h]

| 時間 | 内容 |
|------|------|
| 0:00-1:00 | Subscriber で `/turtle1/pose` を受信するノード作成 |
| 1:00-2:00 | Publisher で `/turtle1/cmd_vel` を送信するノード作成 |
| 2:00-3:00 | 「壁にぶつかったら方向転換」するロジック実装 |
| 3:00-4:00 | `rqt_graph` での可視化とデバッグ |
| 4:00-4:30 | コードのリファクタリング |

#### Day 7（日）: 振り返りと補強 [4.5h]

| 時間 | 内容 |
|------|------|
| 0:00-1:30 | 理解が浅い部分の復習 |
| 1:30-3:00 | QoS（Quality of Service）の概念学習 |
| 3:00-4:00 | Week 1 の学習ノートまとめ |
| 4:00-4:30 | Week 2 の予習 |

### よくあるエラーとトラブルシューティング

| エラー | 原因 | 対処法 |
|--------|------|--------|
| `ros2: command not found` | 環境変数未設定 | `source /opt/ros/humble/setup.bash` を実行 |
| `Package 'xxx' not found` | 未インストール | `sudo apt install ros-humble-xxx` |
| WSLg でウィンドウが表示されない | WSLg 未対応 | Windows を最新に更新、`wsl --update` |
| `colcon build` でエラー | 依存関係の問題 | `rosdep install --from-paths src --ignore-src -r -y` |

### リスクと代替プラン

- **WSLg で GUI が動かない** → VcXsrv を使った X11 フォワーディング
- **ROS 2 インストールに時間がかかる** → Docker イメージ (`osrf/ros:humble-desktop`)
- **Python に不慣れで進捗が遅い** → C++ ノード (`rclcpp`) で実装

---

## Week 2: ROS 2 通信パターン深掘りと turtlesim 実践

### 学習目標

- Service、Action、tf2 の概念を理解して実装できる
- launch ファイルで複数ノードを一括起動できる
- turtlesim を使ったカスタム Pub/Sub ノードを完成させる

### 「完了」基準

- [ ] Service Server/Client のペアが動作する
- [ ] Action Server/Client のペアが動作する
- [ ] tf2 で座標変換ができる（static / dynamic）
- [ ] launch ファイルで 3 つ以上のノードを一括起動できる
- [ ] turtlesim で図形（四角形・星型など）を描くカスタムノードが動く

### 日次スケジュール

#### Day 8（月）: Service パターン [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:45 | Service の概念学習（同期リクエスト/レスポンス） |
| 0:45-1:30 | turtlesim の Service を使う（`/spawn`, `/kill`, `/clear`） |
| 1:30-2:00 | カスタム Service 定義（.srv ファイル）の作成 |
| 2:00-2:30 | Service Server/Client ノードの実装 |

```bash
ros2 service list
ros2 service call /spawn turtlesim/srv/Spawn "{x: 5.0, y: 5.0, theta: 0.0, name: 'turtle2'}"
```

**ファームウェアエンジニア向け補足**: Service は I2C/SPI の「コマンド送信 → 応答受信」に似た同期通信パターン。

#### Day 9（火）: Action パターン [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:45 | Action の概念学習（非同期・フィードバック付き） |
| 0:45-1:30 | turtlesim の Action を使う（`/turtle1/rotate_absolute`） |
| 1:30-2:15 | Action Server/Client の実装 |
| 2:15-2:30 | Pub/Sub vs Service vs Action の使い分け整理 |

**通信パターン比較表**:

| パターン | 方向 | 同期性 | ユースケース | 組み込み類似概念 |
|---------|------|--------|-------------|----------------|
| Topic (Pub/Sub) | 1対多 | 非同期 | センサデータ配信 | UART ストリーム |
| Service | 1対1 | 同期 | 設定変更、状態問い合わせ | I2C コマンド |
| Action | 1対1 | 非同期+FB | 長時間タスク | DMA 転送 + 割り込み |

#### Day 10（水）: tf2 座標変換フレームワーク [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:45 | tf2 の概念学習（座標フレームのツリー構造） |
| 0:45-1:30 | Static Transform Broadcaster の実装 |
| 1:30-2:15 | Dynamic Transform Broadcaster の実装 |
| 2:15-2:30 | Transform Listener でフレーム間の変換を取得 |

```bash
sudo apt install ros-humble-tf2-tools ros-humble-tf2-ros ros-humble-tf2-geometry-msgs
ros2 run tf2_tools view_frames
ros2 run tf2_ros tf2_echo base_link camera_link
```

**ファームウェアエンジニア向け補足**: tf2 はロボティクスで最も頻繁に使う基盤ライブラリ。
IMU のキャリブレーションで回転行列を扱った経験があれば直感的に理解できる。
ロボットの各パーツの位置関係管理、SLAM の地図上のロボット位置管理、
センサデータの統一座標系への変換に使われる。

#### Day 11（木）: Launch ファイルと colcon [2.5h]

| 時間 | 内容 |
|------|------|
| 0:00-0:45 | Python launch ファイルの文法学習 |
| 0:45-1:30 | 複数ノードを起動する launch ファイル作成 |
| 1:30-2:00 | パラメータの外部設定（YAML ファイル） |
| 2:00-2:30 | colcon ビルドシステムの仕組み理解 |

```python
# launch/turtlesim_demo.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(package='turtlesim', executable='turtlesim_node', name='sim'),
        Node(package='my_first_pkg', executable='wall_avoidance', name='controller',
             parameters=[{'speed': 2.0, 'turn_distance': 1.5}]),
    ])
```

```bash
# colcon チートシート
colcon build                                     # 全パッケージ
colcon build --packages-select my_pkg            # 特定パッケージのみ
colcon build --symlink-install                   # Python 向け（シンボリックリンク）
colcon test && colcon test-result --verbose       # テスト実行・結果確認
```

#### Day 12-14: 演習と振り返り

- **Day 12（金）**: turtlesim で正五角形を描くノードを実装 [2h]
- **Day 13（土）**: カスタム Pub/Sub + Service + tf2 の統合演習、launch で一括起動 [4.5h]
- **Day 14（日）**: Week 1-2 振り返り、Gazebo のインストール開始 [4.5h]

### リスクと代替プラン

- **tf2 の数学が難しい** → 使い方に絞り、数学は後回し
- **カスタム Service/Action の定義でビルドエラー** → 既存インターフェース型のみで演習
- **Python 実装が遅い** → C++ (rclcpp) に切り替え

---

## Week 3: シミュレーション環境と URDF

### 学習目標

- Gazebo Sim のセットアップと基本操作を習得する
- URDF でロボットモデルを記述できるようになる
- Gazebo 上でロボットを動かし、センサデータを取得する

### 「完了」基準

- [ ] Gazebo Sim が WSL2 上で起動し、ワールドが表示される
- [ ] カスタム URDF ロボットが Gazebo 上に表示される
- [ ] Gazebo 上のロボットにセンサ（LiDAR, Camera）が付き、ROS 2 トピックにデータが流れる
- [ ] rviz2 でセンサデータ（LaserScan, Image）を可視化できる

### 日次スケジュール

#### Day 15（月）: Gazebo Sim セットアップ [2.5h]

```bash
sudo apt install -y ros-humble-ros-gz
ign gazebo shapes.sdf
ros2 launch ros_gz_sim gz_sim.launch.py gz_args:="shapes.sdf"
```

#### Day 16（火）: URDF 基礎 [2.5h]

- URDF の構造学習（link, joint, visual, collision, inertial）
- シンプルな2リンクロボットの URDF 記述
- rviz2 での表示と `joint_state_publisher_gui`
- xacro によるマクロ活用

```bash
sudo apt install ros-humble-joint-state-publisher-gui ros-humble-robot-state-publisher ros-humble-xacro
```

#### Day 17（水）: Gazebo 上でロボットを動かす [2.5h]

- Gazebo プラグイン（diff_drive, joint_state_publisher）の設定
- URDF に Gazebo 用タグを追加
- Gazebo 上でのロボット spawn と cmd_vel による操作

```bash
sudo apt install ros-humble-teleop-twist-keyboard
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

#### Day 18（木）: センサのシミュレーション [2.5h]

- LiDAR / カメラ / IMU センサの追加
- rviz2 でのセンサデータ可視化

**ROS 2 主要センサメッセージ型**:

| メッセージ型 | 説明 | 用途 |
|-------------|------|------|
| `sensor_msgs/msg/LaserScan` | 2D LiDAR | SLAM、障害物回避 |
| `sensor_msgs/msg/PointCloud2` | 3D 点群 | 3D マッピング |
| `sensor_msgs/msg/Image` | カメラ画像 | 物体検出、VLM 入力 |
| `sensor_msgs/msg/Imu` | 慣性計測 | 姿勢推定 |
| `nav_msgs/msg/Odometry` | オドメトリ | 位置推定 |
| `geometry_msgs/msg/Twist` | 速度指令 | モーター制御 |

#### Day 19（金）: センサデータ処理ノード [2h]

- LaserScan → 障害物検出ノード
- Image → OpenCV 処理ノード（cv_bridge 使用）

#### Day 20-21: 統合演習

- **Day 20（土）**: 差動駆動ロボット完全 URDF 作成、Gazebo ワールド作成、launch 一括起動 [4.5h]
- **Day 21（日）**: 振り返り、SLAM 理論学習、Nav2/slam_toolbox インストール [4.5h]

```bash
sudo apt install ros-humble-slam-toolbox ros-humble-navigation2 ros-humble-nav2-bringup
sudo apt install ros-humble-turtlebot3-gazebo ros-humble-turtlebot3-navigation2
echo 'export TURTLEBOT3_MODEL=burger' >> ~/.bashrc
```

### リスクと代替プラン

- **Gazebo が WSL2 で重い** → TurtleBot3 の既製パッケージを使用
- **URDF 記述が複雑** → 既存モデル（TurtleBot3）をカスタマイズ
- **GPU パススルーが動かない** → CPU レンダリングで進める

---

## Week 4: SLAM と自律ナビゲーション

### 学習目標

- SLAM の仕組みを理解し、slam_toolbox で地図を作成できる
- Nav2 を使ってロボットを自律ナビゲーションさせる
- Gazebo 上で SLAM + 自律ナビゲーションの一連のフローを実行する

### 「完了」基準

- [ ] slam_toolbox でリアルタイムに地図が生成される
- [ ] 生成した地図を保存・読み込みできる
- [ ] Nav2 でゴール地点を指定するとロボットが自律移動する
- [ ] **Month 1 マイルストーン**: Gazebo 上のロボットが SLAM しながら自律走行するデモ動画を撮影

### 日次スケジュール

#### Day 22（月）: SLAM 理論と slam_toolbox [2.5h]

```bash
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
ros2 launch slam_toolbox online_async_launch.py
ros2 run teleop_twist_keyboard teleop_twist_keyboard
ros2 run nav2_map_server map_saver_cli -f ~/maps/my_map
```

**ファームウェアエンジニア向け補足**: SLAM はセンサフュージョンの集大成。
カルマンフィルタの知識があればパーティクルフィルタの理解も速い。

#### Day 23（火）: Nav2 基礎 [2.5h]

```bash
ros2 launch turtlebot3_navigation2 navigation2.launch.py map:=$HOME/maps/my_map.yaml
```

**Nav2 主要コンポーネント**:

| コンポーネント | 役割 |
|--------------|------|
| Global Planner | A* / NavFn で地図上の最短経路を計算 |
| Local Planner | DWB / MPPI でリアルタイム障害物回避 |
| Costmap | 障害物の膨張コストを計算 |
| Recovery | スタック時のバックアップ・回転動作 |
| BT Navigator | Behavior Tree でナビゲーションフロー制御 |

#### Day 24（水）: カスタムワールドでの SLAM [2.5h]

- カスタム Gazebo ワールド作成（部屋・廊下・障害物）
- カスタムワールドで SLAM を実行
- 地図品質の評価と改善

#### Day 25（木）: プログラムからのナビゲーション [2.5h]

```python
from nav2_simple_commander.robot_navigator import BasicNavigator
from geometry_msgs.msg import PoseStamped

navigator = BasicNavigator()
goal_pose = PoseStamped()
goal_pose.header.frame_id = 'map'
goal_pose.pose.position.x = 2.0
goal_pose.pose.position.y = 1.0
goal_pose.pose.orientation.w = 1.0
navigator.goToPose(goal_pose)
while not navigator.isTaskComplete():
    feedback = navigator.getFeedback()
```

#### Day 26-28: 最終課題と振り返り

- **Day 26（金）**: SLAM → 地図保存 → Nav2 ナビゲーションの一連フロー確認 [2h]
- **Day 27（土）**: Month 1 最終デモ構築・動画撮影・GitHub プッシュ [5h]
- **Day 28（日）**: Month 1 振り返り、Month 2 用 AI モデル事前ダウンロード [4.5h]

### リスクと代替プラン

- **SLAM の地図品質が悪い** → cartographer に切り替え
- **Nav2 チューニングに時間がかかる** → TurtleBot3 デフォルトパラメータをそのまま使用
- **Gazebo + SLAM + Nav2 で PC が重い** → シンプルなワールドに変更

---

# Month 2: AI x ロボット連携（Week 5〜8）

---

## Week 5: マルチモーダル AI 概要とローカル推論環境

### 学習目標

- VLM / VLA の概要と主要モデルを理解する
- WSL2 + RTX 5070 でローカル推論環境を構築する
- 画像入力 → テキスト出力のパイプラインを動かす

### 「完了」基準

- [ ] LLaVA または Florence-2 がローカルで動作する
- [ ] 画像を入力して自然言語で説明が返る
- [ ] 推論速度を計測し、ボトルネックを把握している
- [ ] 量子化モデルと非量子化モデルの精度・速度差を比較した

### 日次スケジュール

#### Day 29（月）: VLM / VLA 概要学習 [2.5h]

**VLM 主要モデル比較**:

| モデル | パラメータ数 | 8GB VRAM 対応 |
|--------|------------|--------------|
| LLaVA-1.5-7B | 7B | INT4 で可能 |
| Florence-2-large | 0.7B | FP16 で余裕 |
| MiniCPM-V-2.6 | 8B | INT4 で可能 |
| InternVL2-8B | 8B | INT4 で可能 |

**VLA の概念**: `画像 + 言語指示 → VLA モデル → ロボット動作（End-to-End）`
代表モデル: RT-2, Octo, OpenVLA

#### Day 30（火）: Python 推論環境セットアップ [2.5h]

```bash
conda activate physical-ai
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

#### Day 31（水）: Florence-2 で画像キャプション [2.5h]

```python
from transformers import AutoProcessor, AutoModelForCausalLM
from PIL import Image
import torch, time

model_id = "microsoft/Florence-2-large"
model = AutoModelForCausalLM.from_pretrained(
    model_id, torch_dtype=torch.float16, trust_remote_code=True).to("cuda")
processor = AutoProcessor.from_pretrained(model_id, trust_remote_code=True)

image = Image.open("test_image.jpg")
inputs = processor(text="<CAPTION>", images=image, return_tensors="pt").to("cuda")
start = time.time()
generated_ids = model.generate(input_ids=inputs["input_ids"],
    pixel_values=inputs["pixel_values"], max_new_tokens=1024)
print(f"Inference time: {time.time() - start:.2f}s")
```

#### Day 32（木）: LLaVA でマルチモーダル推論 [2.5h]

```python
from transformers import AutoProcessor, LlavaForConditionalGeneration, BitsAndBytesConfig
import torch

quantization_config = BitsAndBytesConfig(
    load_in_4bit=True, bnb_4bit_compute_dtype=torch.float16, bnb_4bit_quant_type="nf4")
model = LlavaForConditionalGeneration.from_pretrained(
    "llava-hf/llava-1.5-7b-hf", quantization_config=quantization_config, device_map="auto")
processor = AutoProcessor.from_pretrained("llava-hf/llava-1.5-7b-hf")
```

#### Day 33（金）: 量子化手法の比較 [2h]

| 手法 | 特徴 | メリット |
|------|------|---------|
| GPTQ | Post-training（GPU 最適化） | GPU 推論が速い |
| AWQ | Activation-aware 量子化 | 高精度 |
| GGUF | llama.cpp 形式 | CPU/GPU 柔軟 |
| bitsandbytes | HF transformers 統合 | 簡単に使える |

#### Day 34（土）: 推論最適化 [4.5h]

- vLLM / TensorRT-LLM / ONNX Runtime の調査と試行
- バッチ推論とストリーミング推論
- ベンチマーク結果のまとめ、最適構成の決定

#### Day 35（日）: Whisper 音声認識 & 振り返り [4.5h]

```bash
pip install faster-whisper
```

```python
from faster_whisper import WhisperModel
model = WhisperModel('medium', device='cuda', compute_type='float16')
segments, info = model.transcribe('audio.wav', language='ja')
for segment in segments:
    print(f'[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}')
```

### リスクと代替プラン

- **8GB VRAM で LLaVA-7B が動かない** → Florence-2 (0.7B) に絞る
- **vLLM インストールが困難** → transformers + bitsandbytes で進める
- **TensorRT の WSL2 サポートに問題** → ONNX Runtime GPU に切り替え

---

## Week 6: VLM パイプライン構築と最適化

### 学習目標

- カメラ画像 → VLM → テキスト出力のエンドツーエンドパイプラインを構築する
- リアルタイム性を意識した最適化を行う

### 「完了」基準

- [ ] カメラ/シミュレーション画像 → VLM → テキスト出力が連続動作する
- [ ] 推論レイテンシが 3 秒以内
- [ ] パイプラインがモジュール化されており、モデル差し替えが容易

### 日次スケジュール

- **Day 36（月）**: OpenCV カメラ入力パイプライン構築 [2.5h]
- **Day 37（火）**: VLM 推論サーバー化（常駐ロード、非同期推論） [2.5h]
- **Day 38（水）**: 画像取得 → 前処理 → VLM → 結果出力の統合 [2.5h]
- **Day 39（木）**: レイテンシ最適化（プロファイリング、解像度・トークン数調整） [2.5h]
- **Day 40（金）**: テスト・エラーハンドリング [2h]
- **Day 41（土）**: 総合テスト・パフォーマンスレポート・リファクタリング [4.5h]
- **Day 42（日）**: 振り返り、ROS 2 ノードラッパー設計検討 [4.5h]

**ロボット向けプロンプト例**:

```python
prompts = {
    "scene_description": "Describe the scene. Focus on objects, positions, and obstacles.",
    "navigation_advice": "You are a mobile robot. Suggest direction (forward/left/right/stop).",
}
```

### リスクと代替プラン

- **WSL2 で USB カメラ非認識** → Gazebo シミュレーションカメラ画像を使用
- **レイテンシ 3 秒以内に収まらない** → 軽量モデル / 推論頻度を下げる

---

## Week 7: ROS 2 + AI 統合パイプライン設計

### 学習目標

- VLM パイプラインを ROS 2 ノードとして統合する
- カメラ → VLM → 制御の完全パイプラインを構築する

### 「完了」基準

- [ ] カメラノードが `sensor_msgs/Image` を publish する
- [ ] VLM ノードが画像を subscribe して結果テキストを publish する
- [ ] 制御ノードがテキスト指示を受けてロボットを動かす
- [ ] `rqt_graph` で全体のノード接続図が確認できる

### 日次スケジュール

#### Day 43（月）: ROS 2 カメラノード [2.5h]

```python
class CameraNode(Node):
    def __init__(self):
        super().__init__('camera_node')
        self.publisher_ = self.create_publisher(Image, '/camera/image_raw', 10)
        self.bridge = CvBridge()
        self.timer = self.create_timer(0.1, self.timer_callback)  # 10Hz
```

#### Day 44（火）: VLM ROS 2 ノード [2.5h]

```python
class VLMNode(Node):
    def __init__(self):
        super().__init__('vlm_node')
        self.subscription = self.create_subscription(
            Image, '/camera/image_raw', self.image_callback, 10)
        self.publisher_ = self.create_publisher(String, '/vlm/description', 10)
        self.inference_interval = 30  # 30 フレームに 1 回推論
```

#### Day 45（水）: 音声認識 ROS 2 ノード [2.5h]

- Whisper ベースの音声認識ノード実装
- VAD（Voice Activity Detection）の統合

#### Day 46（木）: 制御ノードと統合 [2.5h]

```python
class ControlNode(Node):
    def command_callback(self, msg):
        command = msg.data.lower()
        twist = Twist()
        if 'forward' in command or '前' in command:
            twist.linear.x = 0.5
        elif 'left' in command or '左' in command:
            twist.angular.z = 0.5
        # VLM 障害物情報で安全チェック
        if 'obstacle' in self.last_vlm_description.lower():
            twist.linear.x *= 0.3
        self.cmd_pub.publish(twist)
```

- **Day 47（金）**: ノード間レイテンシ最適化、QoS 調整 [2h]
- **Day 48（土）**: 全ノード launch 統合、Gazebo + VLM + 制御テスト [4.5h]
- **Day 49（日）**: 振り返り、バグ修正、Week 8 デモシナリオ検討 [4.5h]

### リスクと代替プラン

- **VLM 推論遅延が大きい** → VLM は環境認識のみ、制御はルールベース
- **ROS 2 ノード間の画像転送が遅い** → shared memory transport / 画像圧縮
- **WSL2 マイク認識困難** → テキスト入力で代替

---

## Week 8: 統合デモ完成と最適化

### 学習目標

- 「自然言語指示 → ロボット動作」のエンドツーエンドデモを完成させる

### 「完了」基準

- [ ] 「赤いボールの近くに行って」→ ロボットが移動するデモ
- [ ] デモが安定して 5 回連続成功する
- [ ] 全体レイテンシ（指示入力 → 動作開始）が 5 秒以内
- [ ] **Month 2 マイルストーン**: ROS 2 上で VLM 統合デモが動作

### 日次スケジュール

- **Day 50（月）**: デモシナリオ設計、Gazebo ワールドにオブジェクト配置 [2.5h]
- **Day 51（火）**: VLM 出力 → ナビゲーション目標生成 → Nav2 連携 [2.5h]
- **Day 52（水）**: LLM によるテキスト指示解析（インテント分類） [2.5h]
- **Day 53（木）**: エラーリカバリ、ヘルスチェック、安定性改善 [2.5h]
- **Day 54（金）**: ボトルネック分析、メモリ最適化 [2h]
- **Day 55（土）**: デモ通しテスト（5 回連続成功目標）、動画撮影、GitHub プッシュ [5h]
- **Day 56（日）**: Month 2 振り返り、Isaac Sim ダウンロード開始 [4.5h]

### リスクと代替プラン

- **VLM 精度不十分** → デモ簡略化（色検出は OpenCV + VLM はシーン説明のみ）
- **統合が時間内に終わらない** → 音声認識を省きテキスト入力のみ
- **Gazebo パフォーマンス不足** → シンプルワールドに変更

---

# Month 3: シミュレーション & ポートフォリオ（Week 9〜12）

---

## Week 9: NVIDIA Isaac Sim 導入

### 学習目標

- Isaac Sim を Windows 上にセットアップする
- Isaac Sim でのロボットシミュレーションの基本を理解する

### 「完了」基準

- [ ] Isaac Sim が起動しサンプルシーンが動作する
- [ ] ロボット（Carter / Jetbot）を読み込んで操作できる
- [ ] ROS 2 Bridge 経由で Isaac Sim と ROS 2 が通信できる

### 日次スケジュール

- **Day 57（月）**: Omniverse Launcher + Isaac Sim インストール [2.5h]
- **Day 58（火）**: Isaac Sim 基本操作（UI、環境作成、物理設定、USD） [2.5h]
- **Day 59（水）**: ロボットモデル読み込み（URDF → USD 変換） [2.5h]
- **Day 60（木）**: センサシミュレーション（RGB, Depth, LiDAR）、Domain Randomization 概要 [2.5h]
- **Day 61（金）**: ROS 2 Bridge セットアップ、通信確認 [2h]
- **Day 62（土）**: Isaac Sim + ROS 2 統合、Month 2 VLM パイプラインとの接続テスト [4.5h]
- **Day 63（日）**: 振り返り、強化学習の理論予習 [4.5h]

**Domain Randomization**: シミュレーション環境のテクスチャ・照明・物体位置をランダム変化させ、
学習モデルの汎化性能を向上させる手法。Sim-to-Real 転移の鍵。

### リスクと代替プラン

- **RTX 5070 (8GB) でパフォーマンス不足** → 低品質レンダリング / シンプルシーン
- **Isaac Sim インストール問題** → Gazebo での学習を深化
- **ROS 2 Bridge 不安定** → Isaac Sim Python API で直接制御

---

## Week 10: 強化学習とシミュレーション連携

### 学習目標

- 強化学習の基礎（報酬設計、PPO）を理解する
- シミュレーション上で簡単な RL タスクを実行する
- Sim-to-Real 転移の概念を理解する

### 「完了」基準

- [ ] PPO アルゴリズムの仕組みを説明できる
- [ ] シミュレーション上で簡単な RL タスク（ゴール到達）が動く
- [ ] 学習曲線を可視化できる

### 日次スケジュール

- **Day 64（月）**: RL 基礎（状態、行動、報酬、方策、PPO） [2.5h]
- **Day 65（火）**: 報酬設計（Sparse vs Dense、Reward Shaping） [2.5h]
- **Day 66（水）**: シミュレーション RL 環境構築（Gymnasium 互換） [2.5h]
- **Day 67（木）**: PPO 学習実行、TensorBoard モニタリング [2.5h]
- **Day 68（金）**: Sim-to-Real 概念（Domain Randomization、物理ギャップ） [2h]
- **Day 69（土）**: RL モデルをデモに統合、VLM + RL 組み合わせテスト [4.5h]
- **Day 70（日）**: 振り返り、ポートフォリオ構成検討 [4.5h]

```python
# CartPole で PPO の基本を体験
import gymnasium as gym
from stable_baselines3 import PPO
env = gym.make("CartPole-v1")
model = PPO("MlpPolicy", env, verbose=1, tensorboard_log="./ppo_logs/")
model.learn(total_timesteps=50000)
```

**Sim-to-Real の主要課題**:

| 課題 | 対策 |
|------|------|
| 見た目のギャップ | Domain Randomization |
| 物理のギャップ | 物理パラメータのランダム化 |
| センサのギャップ | センサノイズの追加 |
| 動力学のギャップ | System Identification |

### リスクと代替プラン

- **RL 学習が収束しない** → より簡単なタスクに変更
- **GPU メモリが VLM + RL で不足** → 別々に実行

---

## Week 11: ポートフォリオ制作

### 学習目標

- 3ヶ月の成果を GitHub ポートフォリオとして整理する
- デモ動画を作成する

### 「完了」基準

- [ ] GitHub リポジトリが整理されている
- [ ] デモ動画が 2〜3 本撮影されている
- [ ] 再現可能なドキュメントがある

### 日次スケジュール

- **Day 71（月）**: リポジトリ構成設計、メイン README 作成 [2.5h]
- **Day 72（火）**: ROS 2 / VLM コード整理、docstring 追加 [2.5h]
- **Day 73（水）**: 各パッケージ README、API ドキュメント、アーキテクチャ図 [2.5h]
- **Day 74（木）**: デモ動画撮影・編集（OBS Studio） [2.5h]
- **Day 75（金）**: テックブログ執筆 [2h]
- **Day 76（土）**: オプション: Jetson デモ or 追加コンテンツ作成 [4.5h]
- **Day 77（日）**: 振り返り、ブログ執筆続き、未完了タスク棚卸し [4.5h]

**推奨ディレクトリ構成**:

```
learning-physical-ai/
├── README.md
├── docs/
│   ├── ROADMAP.md / SETUP.md / LEARNINGS.md
├── month1-ros2-basics/
│   ├── week1-ros2-intro/ ... week4-slam-nav/
├── month2-ai-robot-integration/
│   ├── week5-vlm-setup/ ... week8-integrated-demo/
├── month3-simulation-portfolio/
│   ├── week9-isaac-sim/ ... week12-final/
├── ros2_ws/src/
│   ├── my_robot_description/ vlm_ros2_node/ robot_control/
├── scripts/ demo/ configs/
```

**ブログ記事案**:
- 「ファームウェアエンジニアが Physical AI に入門した 3ヶ月の記録」
- 「RTX 5070 (8GB) でローカル VLM を動かしてロボットを操る」

---

## Week 12: 仕上げと公開

### 学習目標

- ポートフォリオを最終仕上げして公開する
- 3ヶ月の学習を総括し、次のステップを計画する

### 「完了」基準

- [ ] GitHub ポートフォリオが公開状態
- [ ] テックブログが 1 本以上公開
- [ ] 全デモが再現可能なドキュメント完備
- [ ] **最終マイルストーン**: ポートフォリオとして公開可能な成果物が完成

### 日次スケジュール

- **Day 78（月）**: クリーンインストールからのセットアップ手順検証、全デモ動作確認 [2.5h]
- **Day 79（火）**: ドキュメント最終レビュー、誤字脱字チェック、ライセンス追加 [2.5h]
- **Day 80（水）**: テックブログ公開、SNS 共有 [2.5h]
- **Day 81（木）**: ボーナス - KiCad センサボード設計 [2.5h]
- **Day 82（金）**: 3ヶ月学習総括レポート、次のステップ計画 [2h]
- **Day 83（土）**: 最終コードレビュー、GitHub 公開設定、GitHub Pages（オプション） [5h]
- **Day 84（日）**: 全体振り返り、次の学習ステップの具体計画 [4.5h]

### ボーナス: KiCad カスタムセンサボード設計

ファームウェアエンジニアならではの成果物。ポートフォリオの差別化要素になる。

**想定仕様**:
- MCU: ESP32-S3（WiFi + BLE、micro-ROS 対応）
- IMU: ICM-42688-P（6 軸、SPI 接続）
- ToF: VL53L1X（距離センサ、I2C 接続）
- 温湿度: SHT40（I2C 接続）
- 電源: USB-C (5V) → LDO (3.3V)
- サイズ: 40mm x 30mm

### 3ヶ月で得たスキルの整理

| カテゴリ | 習得スキル |
|---------|----------|
| ROS 2 | Pub/Sub, Service, Action, tf2, launch, Nav2, SLAM |
| シミュレーション | Gazebo Sim, URDF, Isaac Sim |
| AI | VLM (LLaVA, Florence-2), Whisper, 量子化推論 |
| RL | PPO, 報酬設計, Sim-to-Real 概念 |
| 統合 | ROS 2 + VLM パイプライン, 自然言語ロボット制御 |

### 次のステップ候補

1. **実機ロボット**: Jetson + TurtleBot4 / ROSbot
2. **マニピュレーション**: ロボットアーム把持タスク（MoveIt 2）
3. **VLA モデル**: OpenVLA, RT-2 の活用
4. **マルチエージェント**: 複数ロボットの協調制御
5. **Foundation Models**: RoboFlamingo, SayCan, PaLM-E
6. **ハードウェア**: カスタムロボット設計・製作

---

# 補足: 学習リソースまとめ

## 公式ドキュメント

| リソース | URL |
|---------|-----|
| ROS 2 Humble | https://docs.ros.org/en/humble/ |
| Nav2 | https://docs.nav2.org/ |
| Gazebo Sim | https://gazebosim.org/docs |
| Isaac Sim | https://docs.omniverse.nvidia.com/isaacsim/ |
| HF Transformers | https://huggingface.co/docs/transformers/ |
| Stable-Baselines3 | https://stable-baselines3.readthedocs.io/ |

## 書籍・コース

| リソース | 概要 |
|---------|------|
| 『ROS 2 ではじめよう 次世代ロボットプログラミング』 | ROS 2 日本語入門書 |
| Coursera - Robotics Specialization (UPenn) | ロボティクス基礎理論 |
| Spinning Up in Deep RL (OpenAI) | 強化学習入門 |

---

# 補足: ファームウェアエンジニア向け Tips

## C++ ノードの例

パフォーマンスが必要な部分は C++ で書くことを推奨。

```cpp
#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"

class MyPublisher : public rclcpp::Node {
public:
    MyPublisher() : Node("my_publisher"), count_(0) {
        publisher_ = this->create_publisher<std_msgs::msg::String>("my_topic", 10);
        timer_ = this->create_wall_timer(std::chrono::milliseconds(500),
            std::bind(&MyPublisher::timer_callback, this));
    }
private:
    void timer_callback() {
        auto message = std_msgs::msg::String();
        message.data = "Hello ROS 2: " + std::to_string(count_++);
        publisher_->publish(message);
    }
    rclcpp::TimerBase::SharedPtr timer_;
    rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
    size_t count_;
};
```

## micro-ROS でファームウェアスキルを活かす

```
マイコン (STM32/ESP32) ←→ micro-ROS Agent ←→ ROS 2 Graph
     ↑                                         ↑
 センサドライバ                           VLM / Nav2 / etc.
 (I2C/SPI)
```

micro-ROS を使えば、マイコン上で ROS 2 ノードを直接動かせる。
カスタムロボット製作時の大きな武器になる。

---

## 週次チェックリスト（全週共通）

- [ ] その週の「完了」基準を全て満たしているか
- [ ] 学習ノートを書いたか
- [ ] コードを GitHub にプッシュしたか
- [ ] 翌週のスケジュールを確認したか
- [ ] 遅れている部分があれば代替プランを検討したか

---

**このロードマップは、進捗に応じて柔軟に調整すること。**
重要なのは「毎日手を動かし続けること」と「動くものを作り続けること」。
完璧を目指して止まるよりも、不完全でも動くものを公開する方がはるかに価値がある。
