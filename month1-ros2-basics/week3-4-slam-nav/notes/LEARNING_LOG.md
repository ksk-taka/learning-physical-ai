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

### Week 3-4 進捗サマリー（Day 1）
- チェックリスト: 11/22 完了（50%）
- 残り: SDF カスタムワールド, ros_gz ブリッジ, Xacro, センサー追加, SLAM パラメータ調整, コストマップ, プログラムからのNav2制御, Recovery Behaviors, 統合デモ

---

## 2026-03-01: Day 2 — Python ノード開発 + Week 1-2 残り消化

### 開発環境セットアップ
- WSL2 (Ubuntu-22.04) に Node.js 20 + Claude Code をインストール
- VSCode の WSL 拡張でリモート接続 → WSL2 上のファイルを直接編集可能に
- ROS 2 パッケージ `my_robot_pkg` を作成（`~/colcon_ws/src/`）

### 実施内容

#### 1. LaserScan 処理ノード（scan_processor.py）
- `/scan` トピックを Subscribe し、前後左右の距離と最近傍障害物を表示
- `sensor_msgs/msg/LaserScan` の構造を理解:
  - `ranges[360]`: 1度刻み、反時計回りの距離配列
  - `inf`: 障害物なし（レーザーが何にも当たらなかった）
  - `angle_min + index * angle_increment` で実角度を計算

#### 2. Obstacle Avoidance ノード（obstacle_avoidance.py）
- `/scan` を Subscribe → 判断 → `/cmd_vel` に Publish の自律制御パターン
- 前方60度の最小距離が 0.5m 以下で回避旋回、それ以外は直進
- `geometry_msgs/msg/Twist`: `linear.x`（前後速度）, `angular.z`（回転速度）
- Gazebo 上でロボットが壁を避けながら自律走行することを確認

#### 3. Nav2 ゴール送信ノード（nav2_goal_sender.py）
- `nav2_msgs/action/NavigateToPose` の Action Client
- Goal 送信 → Feedback（現在位置）受信 → Result（到達）受信
- yaw → quaternion 変換: `z = sin(yaw/2)`, `w = cos(yaw/2)`
- PoseStamped: `frame_id`（座標系 'map'）+ position + orientation

#### 4. rqt_graph（Week 1-2 残り）
- Nav2 起動中に `rqt_graph` で全ノード構成を可視化
- nav2_goal_sender → bt_navigator → planner_server / controller_server の接続を確認

#### 5. ros2 bag（Week 1-2 残り）
- `/scan` と `/cmd_vel` を 10 秒間記録 → SQLite DB に保存
- `ros2 bag play` で再生 → Gazebo 停止中でもセンサーデータが流れることを確認
- FW のロジアナ波形録画＆再生と同じ概念

#### 6. QoS（Week 1-2 残り）
- `ros2 topic info /scan --verbose` で QoS プロファイルを確認
- RELIABLE vs BEST_EFFORT: 信頼性 vs 低遅延のトレードオフ
- VOLATILE vs TRANSIENT_LOCAL: 過去データの配信有無
- FW でいうと UART+ACK/NAK vs 生 UART

#### 7. パラメータ YAML（Week 1-2 残り）
- Nav2 の `burger.yaml` を確認: ノード名 → `ros__parameters` → パラメータ値
- `params_file:=` で launch 時にカスタムパラメータを渡せる
- FW の `config.h` / `#define` を YAML に外出しした形

### 学んだ ROS 2 パターン（まとめ）
```
Subscribe(sensor) → 判断ロジック → Publish(cmd)   ... Topic パターン
Action Client → Goal → Feedback → Result           ... Action パターン
YAML → ros__parameters → ノード設定               ... パラメータパターン
ros2 bag record/play                                ... データ記録/再生
rqt_graph                                           ... ノード構成可視化
```

### Week 1-2 完了状況
- チェックリスト: **21/21 完了（100%）**
- 全項目クリア

### Week 3-4 進捗サマリー（Day 2）
- チェックリスト: 12/22 完了（55%）
- 新規完了: プログラムからのNav2ゴール送信
- 残り: SDF カスタムワールド, ros_gz ブリッジ, Xacro, センサー追加, SLAM パラメータ調整, コストマップ, Recovery Behaviors, 統合 launch, 統合デモ, デモ動画