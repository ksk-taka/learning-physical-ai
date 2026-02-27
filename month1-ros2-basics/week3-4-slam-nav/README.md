# Week 3-4: シミュレーション & SLAM

## 学習目標

Week 3-4では、Week 1-2で習得したROS 2の基礎を土台に、シミュレーション環境でのロボット開発と自律移動の基盤技術を学ぶ。実機がなくても高度なロボティクス開発ができるシミュレーション駆動の開発手法を体得する。

### この2週間で達成すること

1. **Gazeboのセットアップとros 2連携** - シミュレーション環境の構築と基本操作
2. **URDFでロボットモデルを記述** - ロボットの物理構造をXMLで定義、センサー追加
3. **Nav2による自律移動** - ナビゲーションスタックのセットアップ、経路計画と障害物回避
4. **SLAMの基本** - slam_toolbox、LiDARデータ処理、地図構築
5. **センサーデータの扱い方** - PointCloud2, LaserScan, Image, Imu メッセージの理解

### 到達目標

> **Gazebo上でロボットがSLAMしながら自律走行するデモを完成させる**

---

## 前提知識の確認

### Week 1-2 の完了確認

- [ ] Publisher/Subscriberを自力で書ける
- [ ] Service/Actionの概念を理解している
- [ ] tf2の座標フレームを設定できる
- [ ] launchファイルで複数ノードを管理できる

### 座標変換の理解（復習）

```
  map (地図座標系)                     map->odom:      SLAMが提供
   └── odom (オドメトリ座標系)          odom->base_link: オドメトリが提供
        └── base_link (ロボット本体)    base_link->*:    URDFの固定変換が提供
             ├── lidar_link
             ├── camera_link
             └── imu_link
```

### 線形代数の基礎

SLAMやナビゲーションでは回転の表現としてクォータニオン(x, y, z, w)が標準。IMUドライバでMadgwickフィルタ等のクォータニオン出力を扱ったことがあれば同じ概念。

---

## 推奨学習順序（ステップバイステップ）

### Day 1-2: Gazebo入門

#### Gazeboとは

ロボットのための3D物理シミュレータ。実機不要で開発・テスト可能。SPICE回路シミュレータやHILS（Hardware In the Loop Simulation）に相当する。

```bash
# インストール（ROS 2 Humble対応版）
sudo apt install ros-humble-ros-gz ros-humble-ros-gz-bridge ros-humble-ros-gz-sim

# 起動テスト
ign gazebo shapes.sdf

# GPU認識の確認（WSL2）
nvidia-smi
glxinfo | grep "OpenGL renderer"    # NVIDIA GPUが表示されればOK
```

#### Gazebo-ROSブリッジ（ros_gz）

GazeboとROS 2は別システムだが、ros_gzブリッジで接続できる。

```
Gazebo(物理シミュレーション) <--ros_gz bridge--> ROS 2(ナビゲーション/SLAM/制御)
```

```bash
# ブリッジの起動例
ros2 run ros_gz_bridge parameter_bridge \
    /cmd_vel@geometry_msgs/msg/Twist@ignition.msgs.Twist \
    /scan@sensor_msgs/msg/LaserScan@ignition.msgs.LaserScan
```

#### TurtleBot3で動かしてみる

```bash
sudo apt install ros-humble-turtlebot3-gazebo ros-humble-turtlebot3*
export TURTLEBOT3_MODEL=burger
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py    # Gazebo起動
ros2 run turtlebot3_teleop teleop_keyboard                   # 別ターミナルで操作
```

---

### Day 3-4: URDF & ロボットモデリング

#### URDFとは

URDF（Unified Robot Description Format）はロボットの物理構造をXMLで記述するフォーマット。回路図のネットリストに相当し、部品（Link）と接続（Joint）で構造を定義する。

#### Linkの定義

```xml
<link name="base_link">
  <visual>
    <geometry><box size="0.3 0.2 0.1"/></geometry>    <!-- 見た目 -->
    <material name="blue"><color rgba="0.0 0.0 0.8 1.0"/></material>
  </visual>
  <collision>
    <geometry><box size="0.3 0.2 0.1"/></geometry>    <!-- 衝突判定 -->
  </collision>
  <inertial>
    <mass value="5.0"/>                                <!-- 質量（物理演算に必須） -->
    <inertia ixx="0.01" ixy="0" ixz="0" iyy="0.01" iyz="0" izz="0.01"/>
  </inertial>
</link>
```

#### Jointの種類

| Joint型 | 説明 | ファームウェア対応 |
|---------|------|-------------------|
| `fixed` | 固定接続 | はんだ付け、ネジ止め |
| `continuous` | 無限回転（車輪） | DCモーター |
| `revolute` | 範囲制限付き回転（関節） | サーボモーター |
| `prismatic` | 直線移動 | リニアモーター |

#### 差動駆動ロボットの作成

```xml
<?xml version="1.0"?>
<robot name="my_diff_drive_robot">
  <link name="base_link">
    <visual><geometry><box size="0.3 0.2 0.1"/></geometry></visual>
    <collision><geometry><box size="0.3 0.2 0.1"/></geometry></collision>
    <inertial><mass value="5.0"/>
      <inertia ixx="0.0108" ixy="0" ixz="0" iyy="0.0083" iyz="0" izz="0.0042"/>
    </inertial>
  </link>

  <link name="left_wheel">
    <visual><geometry><cylinder radius="0.05" length="0.02"/></geometry></visual>
    <collision><geometry><cylinder radius="0.05" length="0.02"/></geometry></collision>
    <inertial><mass value="0.5"/>
      <inertia ixx="0.0004" ixy="0" ixz="0" iyy="0.0004" iyz="0" izz="0.0006"/>
    </inertial>
  </link>

  <joint name="left_wheel_joint" type="continuous">
    <parent link="base_link"/><child link="left_wheel"/>
    <origin xyz="0.0 0.12 -0.05" rpy="-1.5708 0 0"/>
    <axis xyz="0 0 1"/>
  </joint>
  <!-- 右車輪、キャスターも同様に定義 -->
</robot>
```

#### センサーの追加（LiDAR例）

```xml
<link name="lidar_link">
  <visual><geometry><cylinder radius="0.03" length="0.04"/></geometry></visual>
</link>
<joint name="lidar_joint" type="fixed">
  <parent link="base_link"/><child link="lidar_link"/>
  <origin xyz="0.1 0.0 0.08"/>
</joint>

<!-- Gazebo用LiDARプラグイン -->
<gazebo reference="lidar_link">
  <sensor type="gpu_lidar" name="lidar">
    <topic>/scan</topic>
    <update_rate>10</update_rate>
    <lidar><scan><horizontal>
      <samples>360</samples><min_angle>-3.14159</min_angle><max_angle>3.14159</max_angle>
    </horizontal></scan><range><min>0.1</min><max>12.0</max></range></lidar>
  </sensor>
</gazebo>
```

#### Xacroマクロ（C言語の#defineに相当）

```xml
<xacro:macro name="wheel" params="prefix reflect">
  <link name="${prefix}_wheel">...</link>
  <joint name="${prefix}_wheel_joint" type="continuous">
    <origin xyz="0.0 ${reflect * wheel_separation / 2} 0.0" rpy="-1.5708 0 0"/>
  </joint>
</xacro:macro>

<xacro:wheel prefix="left" reflect="1"/>
<xacro:wheel prefix="right" reflect="-1"/>
```

```bash
xacro my_robot.urdf.xacro > my_robot.urdf          # Xacro展開
ros2 launch urdf_tutorial display.launch.py model:=my_robot.urdf  # rviz2で確認
```

---

### Day 5-7: SLAM

#### SLAMとは

SLAM（Simultaneous Localization and Mapping）は**自己位置推定と地図構築を同時に行う**技術。GPSなし・地図なしの状態で、センサーデータだけで両方を構築する。IMUのデッドレコニング+補正に近い考え方。

```
1. LiDARで周囲をスキャン  ->  2. 壁・障害物を検出  ->  3. 移動しながら地図を拡張
```

#### LiDARデータの処理

LaserScanは回転式距離センサーの出力。360度分の距離値が配列で格納されている。ToFセンサー（VL53Lxx等）を回転させたものがLiDAR。

```python
from sensor_msgs.msg import LaserScan
import math

class ScanProcessor(Node):
    def __init__(self):
        super().__init__('scan_processor')
        self.subscription = self.create_subscription(LaserScan, '/scan', self.scan_callback, 10)

    def scan_callback(self, msg):
        front_distance = msg.ranges[len(msg.ranges) // 2]        # 正面の距離
        min_distance = min(msg.ranges)                             # 最近接障害物
        min_index = msg.ranges.index(min_distance)
        min_angle = msg.angle_min + min_index * msg.angle_increment
        self.get_logger().info(
            f'Front: {front_distance:.2f}m, Nearest: {min_distance:.2f}m at {math.degrees(min_angle):.1f}deg')
```

#### slam_toolboxのセットアップ

```bash
sudo apt install ros-humble-slam-toolbox
ros2 launch slam_toolbox online_async_launch.py slam_params_file:=./config/slam_params.yaml use_sim_time:=true
```

```yaml
# config/slam_params.yaml
slam_toolbox:
  ros__parameters:
    odom_frame: odom
    map_frame: map
    base_frame: base_link
    scan_topic: /scan
    use_sim_time: true
    resolution: 0.05                # 5cm/pixel
    max_laser_range: 12.0
    minimum_travel_distance: 0.5    # この距離移動で新スキャン追加
    minimum_travel_heading: 0.5     # この角度回転で新スキャン追加
    do_loop_closing: true           # ループクローズ（誤差補正）
```

#### 地図構築の実践

```bash
# ターミナル1: Gazeboシミュレーション起動
# ターミナル2: slam_toolbox起動
# ターミナル3: rviz2でリアルタイム地図表示
# ターミナル4: teleop_twist_keyboard でロボットを手動操作 -> 地図が構築される
```

#### 地図の保存と読み込み

```bash
ros2 run nav2_map_server map_saver_cli -f ~/maps/my_map     # 保存（.pgm + .yaml）
ros2 run nav2_map_server map_server --ros-args -p yaml_filename:=~/maps/my_map.yaml
```

Occupancy Grid Map: 白(0)=通行可能、黒(100)=障害物、灰(-1)=未探索

---

### Day 8-10: Nav2 ナビゲーション

#### Nav2アーキテクチャ

```
  ┌──────────────────── Behavior Tree（行動全体制御・状態遷移）────────────────┐
  │                              │                              │              │
  Global Planner            Local Controller            Recovery Behaviors
  (経路計画: NavFn/A*)      (局所制御: DWB/MPPI)        (異常回復: Spin/BackUp/Wait)
  │                              │
  └──── Costmap2D（コストマップ管理）────┘
        Static Layer(静的地図) + Obstacle Layer(動的障害物) + Inflation Layer(安全マージン)
```

**ファームウェアとの対比**: Behavior Treeは組込みのステートマシン（状態遷移図）に相当。Recovery Behaviorsはウォッチドッグタイマーによるリセットやエラーリトライに相当。

#### Nav2のセットアップ

```bash
sudo apt install ros-humble-navigation2 ros-humble-nav2-bringup
ros2 launch nav2_bringup bringup_launch.py \
    map:=~/maps/my_map.yaml use_sim_time:=true params_file:=./config/nav2_params.yaml
```

#### Global Planner vs Local Controller

- **Global Planner**: 地図全体を見て目標までの最適経路を計算（Dijkstra/A*）
- **Local Controller**: 経路に沿いながらリアルタイム障害物を回避する速度指令を生成（DWB/MPPI）

#### プログラムからのナビゲーション

```python
from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator

class NavigationDemo(Node):
    def __init__(self):
        super().__init__('navigation_demo')
        self.navigator = BasicNavigator()

    def navigate_to_goal(self):
        goal_pose = PoseStamped()
        goal_pose.header.frame_id = 'map'
        goal_pose.header.stamp = self.get_clock().now().to_msg()
        goal_pose.pose.position.x = 3.0
        goal_pose.pose.position.y = 2.0
        goal_pose.pose.orientation.w = 1.0
        self.navigator.goToPose(goal_pose)

        while not self.navigator.isTaskComplete():
            feedback = self.navigator.getFeedback()
            if feedback:
                self.get_logger().info(f'残り時間: {feedback.estimated_time_remaining.sec}s')

    def navigate_waypoints(self):
        waypoints = []
        for (x, y) in [(1.0, 0.0), (2.0, 1.0), (0.0, 2.0), (0.0, 0.0)]:
            pose = PoseStamped()
            pose.header.frame_id = 'map'
            pose.pose.position.x = x
            pose.pose.position.y = y
            pose.pose.orientation.w = 1.0
            waypoints.append(pose)
        self.navigator.followWaypoints(waypoints)
```

#### Nav2パラメータの基本設定

```yaml
# config/nav2_params.yaml（抜粋）
controller_server:
  ros__parameters:
    controller_frequency: 20.0
    FollowPath:
      plugin: "dwb_core::DWBLocalPlanner"
      max_vel_x: 0.5          # 最大前進速度 [m/s]
      max_vel_theta: 1.0      # 最大回転速度 [rad/s]
      acc_lim_x: 2.5          # 前進加速度制限

global_costmap:
  ros__parameters:
    robot_radius: 0.15
    resolution: 0.05

local_costmap:
  ros__parameters:
    robot_radius: 0.15
    resolution: 0.05
    width: 3                  # ローカルコストマップサイズ [m]
    height: 3
```

---

### Day 11-14: 統合プロジェクト

#### 最終デモ: 自律探索ロボット

**要件**: (1) カスタムロボット（URDF: 差動駆動+LiDAR+カメラ+IMU）、(2) カスタムワールド（Gazebo: 部屋+廊下+障害物）、(3) SLAM（自律探索で地図構築）、(4) ナビゲーション（地図上で目標地点へ自律移動）、(5) デモ動画録画

#### 進め方

- **Day 11**: カスタムGazeboワールド作成（SDFで壁・ドア・家具を配置）
- **Day 12**: SLAM + テレオペで動作確認、パラメータチューニング
- **Day 13**: Nav2自律移動の実装、ウェイポイント巡回
- **Day 14**: 統合テスト、デバッグ、デモ動画録画、ドキュメント化

#### launchファイルの統合

```python
# launch/full_demo.launch.py
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # Gazeboシミュレーション、robot_state_publisher、
        # slam_toolbox、Nav2、探索コントローラ を全てここで起動
    ])
```

---

## 練習課題

`exercises/` ディレクトリに詳細が記載されている。

| # | ファイル | 内容 | 難易度 | 想定時間 |
|---|---------|------|--------|---------|
| 1 | `exercise01_gazebo_basics.md` | Gazebo基本操作、ワールド読み込み、ロボット制御 | 初級 | 2-3h |
| 2 | `exercise02_urdf_robot.md` | URDFで差動駆動ロボット作成、センサー付きモデル | 中級 | 3-4h |
| 3 | `exercise03_slam_mapping.md` | slam_toolboxで地図構築、パラメータ調整 | 中級 | 3-4h |
| 4 | `exercise04_nav2_setup.md` | Nav2セットアップ、rviz2からの目標設定 | 中級 | 3-4h |
| 5 | `exercise05_autonomous_navigation.md` | プログラムからナビゲーション制御、ウェイポイント巡回 | 上級 | 4-5h |
| 6 | `exercise06_sensor_integration.md` | 複数センサー（LiDAR+カメラ+IMU）のデータ統合と可視化 | 上級 | 4-5h |
| 7 | `exercise07_full_demo.md` | 全要素統合の最終デモ（SLAM+Navigation+カスタム環境） | 上級 | 6-8h |

---

## 到達確認チェックリスト

### Gazebo
- [ ] Gazeboが正常に起動・動作する（WSL2環境）
- [ ] SDFファイルでカスタムワールドを定義できる
- [ ] ros_gzブリッジでGazeboとROS 2を接続できる
- [ ] Gazebo内のロボットをROS 2トピックで制御できる

### URDF
- [ ] URDFの構造（Link, Joint）を理解している
- [ ] 差動駆動ロボットのURDFを作成できる
- [ ] センサー（LiDAR, カメラ, IMU）をURDFに追加できる
- [ ] Xacroでモジュラーなロボット定義を書ける
- [ ] robot_state_publisherでtf2ツリーを公開できる

### SLAM
- [ ] SLAMの原理を説明できる
- [ ] LaserScanデータの構造を理解している
- [ ] slam_toolboxで地図を構築できる
- [ ] 地図の保存と読み込みができる
- [ ] SLAMパラメータの基本的な調整ができる

### Navigation
- [ ] Nav2のアーキテクチャを説明できる
- [ ] Global PlannerとLocal Controllerの役割を理解している
- [ ] コストマップの概念を理解している
- [ ] rviz2から目標地点を設定して自律移動させられる
- [ ] プログラムからナビゲーションゴールを送信できる
- [ ] Recovery Behaviorsの概念を理解している

### 統合
- [ ] 全システムをlaunchファイルで一括起動できる
- [ ] SLAM + Navigationの統合デモが動作する
- [ ] デモ動画を作成した

---

## つまずきやすいポイントと対処法

### 1. GazeboがWSL2で起動しない / クラッシュする

```bash
nvidia-smi                                    # GPU認識確認
export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA  # GPU指定
ign gazebo --headless-rendering -s my_world.sdf # ヘッドレスモード（GUI不要時）

# WSL2のメモリ制限を拡大: C:\Users\<user>\.wslconfig
# [wsl2]
# memory=12GB
# swap=4GB
```

### 2. URDFの構文エラー

```bash
check_urdf my_robot.urdf                      # 構文チェック
xacro my_robot.urdf.xacro > /tmp/robot.urdf   # Xacro展開確認

# よくあるミス: <inertial>の欠落（Gazeboでは必須）、origin座標指定ミス、
# Joint の parent/child 指定ミス、閉じタグ不一致
```

### 3. tf2ツリーの問題

```bash
ros2 run tf2_tools view_frames    # ツリー確認（途切れていないか）
ros2 run tf2_ros tf2_echo map base_link  # 特定フレーム間の変換確認

# よくある原因: robot_state_publisher未起動、フレーム名の不一致、
# use_sim_timeの設定不整合
```

### 4. Nav2のパラメータチューニング

```yaml
# 障害物に近づきすぎる -> inflation_radius を大きくする
inflation_layer:
  inflation_radius: 0.55

# ゴール到達判定が厳しすぎる -> tolerance を大きくする
goal_checker:
  xy_goal_tolerance: 0.25
  yaw_goal_tolerance: 0.25
```

### 5. SLAMの品質問題

- ロボットをゆっくり動かす（急旋回を避ける）
- 特徴が少ない環境（長い廊下等）は苦手 -> 壁にオブジェクトを追加
- LiDARの更新レートを確認（最低10Hz推奨）
- minimum_travel_distanceを小さくしてスキャン頻度を上げる

### 6. WSL2のパフォーマンス問題

```bash
nvidia-smi    # RTX 5070の8GB VRAMを超えていないか確認

# 対処: Gazeboの物理ステップ調整、不要なGUI表示を無効化、
# rviz2のPointCloud2表示を消す、WSL2のリソース割り当て拡大
```

---

## センサーデータ リファレンス

| メッセージ型 | 用途 | ファームウェア対応 |
|---|---|---|
| `sensor_msgs/LaserScan` | 2D LiDAR（角度ごとの距離値配列） | ToFセンサー配列 |
| `sensor_msgs/PointCloud2` | 3D LiDAR/深度カメラ（3D点群） | 3Dスキャナデータ |
| `sensor_msgs/Image` | カメラ画像（ピクセル配列） | カメラモジュールのフレームバッファ |
| `sensor_msgs/Imu` | IMU（加速度+角速度+姿勢） | MPU-6050等のIMU生データ |
| `nav_msgs/OccupancyGrid` | 地図（2Dグリッド占有確率） | - |
| `nav_msgs/Odometry` | オドメトリ（位置+速度+共分散） | エンコーダからの推定位置 |

---

## 参考リンク

### 公式ドキュメント

| リソース | URL |
|---------|-----|
| Gazebo Sim ドキュメント | https://gazebosim.org/docs |
| URDF チュートリアル | https://docs.ros.org/en/humble/Tutorials/Intermediate/URDF/URDF-Main.html |
| Nav2 ドキュメント | https://docs.nav2.org/ |
| slam_toolbox GitHub | https://github.com/SteveMacenski/slam_toolbox |
| ros_gz ブリッジ | https://github.com/gazebosim/ros_gz |

### 推奨学習リソース

| リソース | URL | 備考 |
|---------|-----|------|
| Articulated Robotics - URDF | https://articulatedrobotics.xyz/tutorials/ready-for-ros/urdf/ | URDF入門に最適 |
| Nav2 チュートリアル | https://docs.nav2.org/tutorials/index.html | 公式チュートリアル |
| TurtleBot3 マニュアル | https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/ | 実践リファレンス |
| ROS Answers | https://answers.ros.org/ | トラブルシューティング |

---

> **次のステップ**: Month 1の全課題を完了したら、[Month 2: AI + ロボット統合](../../month2-ai-robot-integration/README.md) に進む。Month 1で培ったROS 2の基盤に、コンピュータビジョンや強化学習を統合していく。
