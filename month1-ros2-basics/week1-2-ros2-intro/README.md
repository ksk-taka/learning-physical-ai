# Week 1-2: ROS 2入門

## 学習目標

Week 1-2では、ROS 2の基礎を徹底的に習得する。ファームウェアエンジニアとしての経験を活かしながら、ロボットソフトウェア開発の基本パターンを身につける。

### この2週間で達成すること

1. **ROS 2 Humbleの環境構築と動作確認** - WSL2上での環境構築、基本CLIコマンドの習得
2. **コア概念の理解と実践** - Publisher/Subscriber、Service、Action、tf2
3. **turtlesimを使った実践演習** - プログラムによるロボット制御の体験
4. **launchファイルの書き方** - 複数ノードの一括起動と管理
5. **colconビルドシステムの理解** - パッケージの作成とビルド

### 到達目標

> **独自のPublisher/Subscriberノードを書いて、turtlesimと連携できる状態**

独自ノードからturtlesimに速度指令を送り、turtlesimの位置情報を受信して処理するプログラムを自力で書けるようになること。

---

## 前提知識の確認

### Linux基礎

```bash
cd, ls, mkdir, pwd, rm              # ディレクトリ操作
sudo apt update, sudo apt install    # パッケージ管理
nano / vim / VSCode                  # テキスト編集
ps, kill, Ctrl+C                     # プロセス管理
export, echo $PATH, source           # 環境変数
```

### Python基礎

```python
# クラスの定義と継承（ROS 2ノードはNodeクラスを継承して作る）
class MyNode(Node):
    def __init__(self):
        super().__init__('my_node')

# コールバック関数（メッセージ受信時に呼ばれる）
def callback(self, msg):
    self.get_logger().info(f'Received: {msg.data}')
```

### Pub/Subパターン（MQTTとの比較）

ファームウェアエンジニアなら**MQTT**を知っているかもしれない。ROS 2のPub/Subは基本的に同じ概念である。

```
MQTT:   Publisher --[topic名]--> Broker        --[topic名]--> Subscriber
ROS 2:  Publisher --[topic名]--> DDS(ミドルウェア) --[topic名]--> Subscriber

違い: ROS 2はメッセージに「型」があり、QoS設定が細かく、ローカル通信が中心
```

---

## 推奨学習順序（ステップバイステップ）

### Day 1-2: 環境構築とROS 2の世界観

#### 環境の確認

詳細な環境構築手順は `docs/SETUP.md` を参照すること。

```bash
source /opt/ros/humble/setup.bash    # ROS 2環境の読み込み（毎回必要）
ros2 --version                       # バージョン確認
echo $ROS_DISTRO                     # 期待値: humble

# .bashrcに追記して自動読み込み
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
```

#### ROS 2の世界観

ROS 2では、全てが**ノード（Node）**で構成される。

```
  ┌──────────┐    /cmd_vel     ┌──────────┐
  │  制御     │───(Twist)────>│  ロボット  │    ノード = 独立プロセス（マイコンの各タスクに相当）
  │  ノード   │               │  ノード   │    トピック = データチャネル（UARTの通信路に相当）
  └──────────┘               └──────────┘    メッセージ = 流れるデータ（パケットに相当）
       ^           /odom          │
       └────(Odometry)───────────┘
```

#### 最初のROS 2コマンド

```bash
ros2 run turtlesim turtlesim_node          # turtlesimを起動
# 別ターミナルで:
ros2 node list                              # ノード一覧 -> /turtlesim
ros2 topic list                             # トピック一覧
ros2 topic info /turtle1/cmd_vel            # 型確認 -> geometry_msgs/msg/Twist
ros2 topic echo /turtle1/pose               # データをリアルタイム確認
ros2 run turtlesim turtle_teleop_key        # キーボードで亀を操作
ros2 run rqt_graph rqt_graph               # ノード間通信をグラフで可視化
```

---

### Day 3-4: Publisher / Subscriber

**ファームウェアとの対比**: Publisher = 割り込みでバッファに書く処理、Subscriber = コールバックで受け取るハンドラ、Topic = 共有リングバッファ

#### Pythonで最初のPublisherを書く

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class MinimalPublisher(Node):
    def __init__(self):
        super().__init__('minimal_publisher')
        self.publisher_ = self.create_publisher(String, 'topic', 10)
        self.timer = self.create_timer(0.5, self.timer_callback)  # タイマー割り込みと同じ
        self.i = 0

    def timer_callback(self):
        msg = String()
        msg.data = f'Hello World: {self.i}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.i += 1

def main(args=None):
    rclpy.init(args=args)
    node = MinimalPublisher()
    rclpy.spin(node)  # イベントループ（FreeRTOSのvTaskStartScheduler()に相当）
    node.destroy_node()
    rclpy.shutdown()
```

#### Pythonで最初のSubscriberを書く

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class MinimalSubscriber(Node):
    def __init__(self):
        super().__init__('minimal_subscriber')
        self.subscription = self.create_subscription(
            String, 'topic', self.listener_callback, 10)

    def listener_callback(self, msg):
        self.get_logger().info(f'I heard: "{msg.data}"')  # 割り込みハンドラに相当

def main(args=None):
    rclpy.init(args=args)
    rclpy.spin(MinimalSubscriber())
```

#### よく使うメッセージ型

| メッセージ型 | 用途 | ファームウェア対応 |
|---|---|---|
| `std_msgs/String` | 文字列データ | UARTテキスト送信 |
| `geometry_msgs/Twist` | 速度指令（並進+回転） | モーターPWM値 |
| `sensor_msgs/LaserScan` | LiDARデータ | ADC距離センサー値 |
| `sensor_msgs/Imu` | IMUデータ | I2C経由のIMU生データ |
| `nav_msgs/Odometry` | 位置・速度 | エンコーダカウント値 |

#### QoS（Quality of Service）

```python
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy

sensor_qos = QoSProfile(  # センサー向け（最新値重視、欠落許容 = UDP的）
    reliability=ReliabilityPolicy.BEST_EFFORT, history=HistoryPolicy.KEEP_LAST, depth=5)

command_qos = QoSProfile(  # コマンド向け（確実配送 = TCP的）
    reliability=ReliabilityPolicy.RELIABLE, history=HistoryPolicy.KEEP_LAST, depth=10)
```

---

### Day 5-6: Service と Action

#### Service: 同期リクエスト/レスポンス

```
SPI通信:       Master ---[コマンド]---> Slave / Master <---[応答]--- Slave
ROS 2 Service: Client ---[Request]---> Server / Client <---[Response]--- Server
-> どちらも「呼んだら返ってくる」同期パターン
```

```bash
ros2 service list                     # turtlesimのサービス一覧
ros2 service call /spawn turtlesim/srv/Spawn "{x: 2.0, y: 2.0, theta: 0.0, name: 'turtle2'}"
```

```python
# Serviceサーバー
from example_interfaces.srv import AddTwoInts

class AddTwoIntsServer(Node):
    def __init__(self):
        super().__init__('add_two_ints_server')
        self.srv = self.create_service(AddTwoInts, 'add_two_ints', self.callback)

    def callback(self, request, response):
        response.sum = request.a + request.b
        return response
```

#### Action: 非同期長時間タスク

```
DMA転送:     開始 -> [転送中] -> 進捗割り込み(50%) -> [転送中] -> 完了割り込み(結果)
ROS 2 Action: Goal -> [実行中] -> Feedback(50%)    -> [実行中] -> Result(結果)
```

```bash
ros2 action send_goal /turtle1/rotate_absolute \
    turtlesim/action/RotateAbsolute "{theta: 1.57}" --feedback
```

#### 使い分けの指針

| パターン | 用途 | 例 | ファームウェア対応 |
|---------|------|-----|------------------|
| **Topic** | 継続的データストリーム | センサーデータ、速度指令 | UART送信、ADC読み取り |
| **Service** | 短い同期処理 | パラメータ取得、状態問い合わせ | SPI/I2Cレジスタ読み書き |
| **Action** | 長時間の非同期処理 | ナビゲーション、アーム動作 | DMA転送、OTA更新 |

---

### Day 7-8: tf2 座標変換

ロボットには複数のセンサーがあり、各センサーのデータを統合するには座標変換が必要。IMUのセンサーフュージョン（加速度計+ジャイロ+磁気計の座標合成）と本質的に同じ。

```
  camera_link(カメラの座標系)
       │
  lidar_link --- base_link(ロボット本体) --- imu_link
                     │
                odom(世界座標系)
  tf2がこれらの座標系間の変換を管理する
```

#### Static Transform（固定: 基板上のセンサー配置と同じ）

```python
from tf2_ros.static_transform_broadcaster import StaticTransformBroadcaster
from geometry_msgs.msg import TransformStamped

class StaticFramePublisher(Node):
    def __init__(self):
        super().__init__('static_frame_publisher')
        self.tf_static_broadcaster = StaticTransformBroadcaster(self)
        t = TransformStamped()
        t.header.stamp = self.get_clock().now().to_msg()
        t.header.frame_id = 'base_link'
        t.child_frame_id = 'camera_link'
        t.transform.translation.x = 0.1   # X方向に10cm
        t.transform.translation.z = 0.3   # Z方向に30cm（上方）
        t.transform.rotation.w = 1.0      # 回転なし
        self.tf_static_broadcaster.sendTransform(t)
```

#### Dynamic Transform（動的: エンコーダから算出する現在位置と同じ）

```python
from tf2_ros import TransformBroadcaster

class DynamicFramePublisher(Node):
    def __init__(self):
        super().__init__('dynamic_frame_publisher')
        self.tf_broadcaster = TransformBroadcaster(self)
        self.timer = self.create_timer(0.1, self.broadcast_timer_callback)

    def broadcast_timer_callback(self):
        t = TransformStamped()
        t.header.stamp = self.get_clock().now().to_msg()
        t.header.frame_id = 'odom'
        t.child_frame_id = 'base_link'
        t.transform.translation.x = self.current_x  # オドメトリから取得
        t.transform.translation.y = self.current_y
        self.tf_broadcaster.sendTransform(t)
```

```bash
rviz2                                  # 3D可視化（"Add" -> "TF" で表示）
ros2 run tf2_tools view_frames         # フレーム構造をPDF出力
```

---

### Day 9-10: パッケージ作成とビルド

#### パッケージの作成

```bash
mkdir -p ~/ros2_ws/src && cd ~/ros2_ws/src
ros2 pkg create --build-type ament_python my_python_pkg --dependencies rclpy std_msgs geometry_msgs
ros2 pkg create --build-type ament_cmake my_cpp_pkg --dependencies rclcpp std_msgs geometry_msgs
```

```
my_python_pkg/
├── package.xml           # メタ情報・依存関係（ファームウェアのCMakeLists.txt的役割）
├── setup.py              # Pythonビルド設定
├── my_python_pkg/        # ソースコード
│   ├── __init__.py
│   └── my_publisher.py
├── launch/               # launchファイル
└── config/               # パラメータ設定
```

#### colconビルド（cmake/makeとの対比）

| cmake/make | colcon | 説明 |
|---|---|---|
| `CMakeLists.txt` | `package.xml` + `setup.py` | ビルド定義 |
| `mkdir build && cd build && cmake .. && make` | `colcon build` | ビルド実行（全自動） |
| 依存関係の手動管理 | `rosdep install` | 依存関係の自動解決 |

```bash
cd ~/ros2_ws && colcon build                          # 全パッケージをビルド
colcon build --packages-select my_python_pkg          # 特定パッケージのみ
source install/setup.bash                             # ビルド後に環境読み込み（必須！）
```

#### launchファイル

```python
# launch/turtlesim_demo.launch.py（システム起動の初期化シーケンスに相当）
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(package='turtlesim', executable='turtlesim_node', name='sim',
             parameters=[{'background_r': 0, 'background_g': 0, 'background_b': 50}]),
        Node(package='my_python_pkg', executable='turtle_controller',
             name='controller', output='screen'),
    ])
```

#### パラメータ管理

```yaml
# config/params.yaml
turtle_controller:
  ros__parameters:
    speed: 2.0
    turn_rate: 1.5
```

```python
class TurtleController(Node):
    def __init__(self):
        super().__init__('turtle_controller')
        self.declare_parameter('speed', 1.0)
        self.speed = self.get_parameter('speed').value
```

---

### Day 11-14: 統合演習

#### マルチタートルコントローラー

Week 1-2の集大成として、全要素を統合したプロジェクトを作成する。

**要件**: (1) 複数の亀を生成（Service）、(2) 各亀を独立制御（Pub/Sub）、(3) 位置トラッキング（tf2）、(4) フォーメーション制御（Action）、(5) launchファイルで一括起動、(6) パラメータでカスタマイズ、(7) ros2 bagでデータ記録・再生

```bash
ros2 bag record /turtle1/pose /turtle2/pose /turtle1/cmd_vel   # データ記録
ros2 bag play rosbag2_<timestamp>                               # データ再生
ros2 bag info rosbag2_<timestamp>                               # 情報確認
```

---

## 練習課題

`exercises/` ディレクトリに詳細が記載されている。順番に取り組むこと。

| # | ファイル | 内容 | 難易度 | 想定時間 |
|---|---------|------|--------|---------|
| 1 | `exercise01_hello_publisher.md` | 基本的なPublisherノード作成 | 初級 | 1-2h |
| 2 | `exercise02_subscriber_logger.md` | Subscriberノードでデータ受信・ログ出力 | 初級 | 1-2h |
| 3 | `exercise03_turtle_shapes.md` | turtlesimに幾何学図形（正方形、三角形、円、星形）を描画 | 中級 | 2-3h |
| 4 | `exercise04_custom_service.md` | カスタムサービスの定義と実装（計算サービス） | 中級 | 2-3h |
| 5 | `exercise05_tf2_frames.md` | tf2フレームツリー構築、座標変換の設定・取得 | 中級 | 2-3h |
| 6 | `exercise06_launch_system.md` | 複数ノードのlaunchファイル、パラメータ外部設定 | 中級 | 2-3h |
| 7 | `exercise07_integration.md` | 全概念を統合したマルチタートル制御システム | 上級 | 4-6h |

---

## 到達確認チェックリスト

### 環境・基礎
- [ ] WSL2上でROS 2 Humbleが正常に動作する
- [ ] `source /opt/ros/humble/setup.bash` の意味と必要性を理解している
- [ ] ROS 2の基本CLIコマンド（`ros2 node`, `ros2 topic`, `ros2 service`, `ros2 action`）を使える
- [ ] rqt_graph でノード間の通信を可視化できる

### Publisher / Subscriber
- [ ] Publisherノードをゼロから書ける（コピペせずに）
- [ ] Subscriberノードをゼロから書ける（コピペせずに）
- [ ] メッセージ型（std_msgs, geometry_msgs）を適切に選択・使用できる
- [ ] QoSの基本設定を理解し、適切なプロファイルを選択できる
- [ ] `ros2 topic echo` でデバッグできる

### Service / Action
- [ ] Serviceサーバー/クライアントを実装できる
- [ ] Actionの概念（Goal, Feedback, Result）を説明できる
- [ ] Topic, Service, Actionの使い分けを判断できる

### tf2
- [ ] 座標フレームの概念を説明できる
- [ ] Static TransformとDynamic Transformの違いを理解している
- [ ] TransformBroadcasterとTransformListenerを使える
- [ ] rviz2でフレームを可視化できる

### パッケージ・ビルド
- [ ] ROS 2パッケージを作成できる
- [ ] colcon buildでビルド・インストールできる
- [ ] launchファイルで複数ノードを管理できる
- [ ] パラメータをYAMLファイルで設定できる
- [ ] ros2 bagでデータを記録・再生できる

---

## つまずきやすいポイントと対処法

### 1. sourceを忘れる（最も頻出）

**症状**: `ros2: command not found` または `Package not found`

```bash
source /opt/ros/humble/setup.bash        # ROS 2本体
source ~/ros2_ws/install/setup.bash      # 自分のワークスペース
# 恒久対策: .bashrcに両方を追記
```

### 2. DDS通信の問題（WSL2特有）

**症状**: ノード間で通信できない、トピックが見つからない

```bash
sudo apt install ros-humble-rmw-cyclonedds-cpp
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp   # CycloneDDSに切替（WSL2推奨）
echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc
```

### 3. GUI表示の問題（rviz2, rqt）

**症状**: rviz2やrqtが起動しない、画面が真っ黒

```bash
xclock                                   # WSLg動作確認（時計が表示されればOK）
glxinfo | grep "OpenGL renderer"         # GPU確認
export LIBGL_ALWAYS_SOFTWARE=1           # 最終手段: ソフトウェアレンダリング
```

### 4. colcon buildのエラー

```bash
rosdep install --from-paths src --ignore-src -y   # 依存パッケージ自動インストール
# setup.pyのconsole_scripts: 'node名 = パッケージ.モジュール:main' を確認
# package.xmlの<exec_depend>が漏れていないか確認
rm -rf build/ install/ log/ && colcon build       # キャッシュクリアして再ビルド
```

### 5. Python vs C++ ノードの違い

| Python | C++ |
|--------|-----|
| プロトタイプが速い | 実行性能が高い |
| AI/MLライブラリ連携が容易 | リアルタイム処理向き |
| setup.py でエントリポイント設定 | CMakeLists.txt でビルド設定 |

Week 1-2ではPythonで始め、概念を理解してからC++に移行するのを推奨する。

### 6. ネットワーク関連のトラブル（WSL2特有）

```bash
export ROS_DOMAIN_ID=42           # 他のROS 2ネットワークと分離
export ROS_LOCALHOST_ONLY=1       # localhost通信のみに限定（WSL2推奨）
```

---

## 参考リンク

### 公式ドキュメント

| リソース | URL |
|---------|-----|
| ROS 2 Humble チュートリアル | https://docs.ros.org/en/humble/Tutorials.html |
| ROS 2 コンセプト | https://docs.ros.org/en/humble/Concepts.html |
| tf2 チュートリアル | https://docs.ros.org/en/humble/Tutorials/Intermediate/Tf2/Tf2-Main.html |
| launch チュートリアル | https://docs.ros.org/en/humble/Tutorials/Intermediate/Launch/Launch-Main.html |

### 推奨学習リソース

| リソース | URL | 備考 |
|---------|-----|------|
| The Robotics Back-End | https://roboticsbackend.com/category/ros2/ | 実践的チュートリアル |
| Articulated Robotics | https://articulatedrobotics.xyz/ | 初心者向け |
| rclpy API | https://docs.ros2.org/latest/api/rclpy/ | Python APIリファレンス |
| rclcpp API | https://docs.ros2.org/latest/api/rclcpp/ | C++ APIリファレンス |

---

> **次のステップ**: Week 1-2の学習が完了したら、[Week 3-4: シミュレーション & SLAM](../week3-4-slam-nav/README.md) に進む。
