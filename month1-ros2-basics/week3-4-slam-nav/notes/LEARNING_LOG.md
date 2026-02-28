# Week 3-4 学習ログ

## 2026-02-28: Day 1 — Gazebo + SLAM + Nav2 体験

### 実施内容

#### 1. Gazebo セットアップ（WSL2）
- TurtleBot3 Burger を Gazebo Classic (gazebo11) でシミュレーション起動
- 初回起動時のモデルダウンロードに時間がかかり spawn_entity がタイムアウト（30秒制限）
- 2回目以降はモデルがキャッシュされ高速に起動
- Gazebo GUI は WSL2 + ソフトウェアレンダリングで表示可能（FPS 30〜50）

**起動手順:**
```bash
export TURTLEBOT3_MODEL=burger
export GAZEBO_MODEL_PATH=/opt/ros/humble/share/turtlebot3_gazebo/models
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
# spawn がタイムアウトした場合の手動スポーン:
ros2 run gazebo_ros spawn_entity.py -entity burger \
  -file /opt/ros/humble/share/turtlebot3_gazebo/models/turtlebot3_burger/model.sdf \
  -x -2.0 -y -0.5 -z 0.01
```

**学んだこと:**
- gzserver = 物理エンジン（ヘッドレス可）、gzclient = 3D ビューア
- gazebo_ros プラグインが Gazebo ↔ ROS 2 のブリッジ役
- `/scan`, `/odom`, `/cmd_vel`, `/imu` などのトピックが自動生成される
- Gazebo = HILS（Hardware In the Loop Simulation）に相当

#### 2. teleop（手動操作）
- `ros2 run turtlebot3_teleop teleop_keyboard` でキーボード操作
- `/cmd_vel` トピック（geometry_msgs/Twist）に速度指令を publish

**操作方法:**
- `w`/`x` = linear velocity 増減（前進/後退）
- `a`/`d` = angular velocity 増減（左/右回転）
- `s` = 停止（velocity を 0 にリセット）

**学んだこと:**
- teleop = `/cmd_vel` に Twist メッセージを publish しているだけ
- FW で言うとモーター PWM 値を送信するのと同じ
- Burger の最大速度: linear 0.22 m/s, angular 2.84 rad/s

#### 3. SLAM（地図構築）
- slam_toolbox で LiDAR データからリアルタイム地図構築
- teleop で六角形コース内を走行し、Occupancy Grid Map を構築
- RViz2 で `/map`（Map）と `/scan`（LaserScan）を可視化

**起動コマンド:**
```bash
ros2 launch slam_toolbox online_async_launch.py use_sim_time:=true
```

**地図の保存:**
```bash
mkdir -p ~/maps
ros2 run nav2_map_server map_saver_cli -f ~/maps/turtlebot3_world
# → .pgm（画像）+ .yaml（メタデータ）
```

**学んだこと:**
- SLAM = Simultaneous Localization and Mapping（自己位置推定 + 地図構築を同時に）
- LiDAR(/scan) → slam_toolbox → 地図(/map) + 位置推定(map→odom TF)
- Occupancy Grid: 白(0)=通行可能, 黒(100)=壁, 灰(-1)=未探索
- ゆっくり動かすほど地図品質が向上（急旋回は品質劣化の原因）

#### 4. Nav2（自律ナビゲーション）
- 保存した地図を読み込み、Nav2 で自律走行
- RViz2 の 2D Pose Estimate で初期位置設定、Nav2 Goal で目標指定

**起動コマンド:**
```bash
ros2 launch turtlebot3_navigation2 navigation2.launch.py \
  use_sim_time:=true map:=$HOME/maps/turtlebot3_world.yaml
```

**RViz2 操作:**
1. 2D Pose Estimate → ロボットの現在位置をクリック＆ドラッグで指定
2. Nav2 Goal → 目標地点をクリック＆ドラッグ → 自動走行開始

**学んだこと:**
- Nav2 アーキテクチャ: Global Planner（経路計画）→ Local Controller（障害物回避）→ /cmd_vel
- Global Planner = A*/Dijkstra で地図全体の最短経路を計算
- Local Controller = DWB でリアルタイム障害物回避しながら速度指令生成
- Nav2 = FW の自律走行制御（経路計画 + 障害物回避 + 状態遷移マシン）

### WSL2 トラブルシュート（Gazebo編）
- Gazebo Classic の GUI が黒画面 → 初回モデルダウンロード完了を待てば表示される
- spawn_entity タイムアウト → gzserver の初期化に30秒以上かかる場合あり、手動で再スポーン
- ALSA エラー → 無害（WSL2 にサウンドカードがないため）
- ロボットがコース外にスポーン → 座標 (-2.0, -0.5, 0.01) が正しい開始位置

### 使用ターミナル構成
```
ターミナル1: ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
ターミナル2: ros2 run turtlebot3_teleop teleop_keyboard
ターミナル3: ros2 launch slam_toolbox online_async_launch.py use_sim_time:=true
ターミナル4: rviz2（または Nav2 launch が自動起動）
```

### Week 3-4 進捗サマリー
- チェックリスト: 11/22 完了（50%）
- 残り: SDF カスタムワールド, ros_gz ブリッジ, Xacro, センサー追加, SLAM パラメータ調整, コストマップ, プログラムからのNav2制御, Recovery Behaviors, 統合デモ