# Week 1-2 学習ログ

## 2025-02-27: Day 1 — 環境構築 & ROS 2 基礎3パターン

### 実施内容

#### 1. 環境構築
- WSL2 に Ubuntu 22.04 をインストール（既存の 24.04 と共存）
- ROS 2 Humble フルインストール（`ros-humble-desktop` + Nav2, SLAM, Gazebo, TurtleBot3, rqt 等 489パッケージ）
- GPU: RTX 5070 認識済み（CUDA 12.9, Driver 577.05）
- `~/.bashrc` に ROS 2 環境設定を追記

#### 2. Publisher / Subscriber（Topic通信）
- `my_first_pkg` パッケージを作成（`ament_python`）
- `hello_publisher.py`: 1秒間隔で `/greeting` トピックに String メッセージを配信
- `hello_subscriber.py`: `/greeting` をサブスクライブしてログ出力
- 動作確認: 2ターミナルで Pub/Sub 通信成功

**学んだこと:**
- `create_publisher()` / `create_subscription()` / `create_timer()` の基本API
- `rclpy.spin()` = FreeRTOS の `vTaskStartScheduler()` に相当
- Topic = 一方通行の非同期データストリーム

#### 3. Service（Request/Response）
- `add_two_ints_server.py`: `example_interfaces/srv/AddTwoInts` を使ったサービスサーバー
- `add_two_ints_client.py`: `call_async()` で非同期リクエスト送信
- 動作確認: `5 + 12 = 17` のリクエスト/レスポンス成功

**学んだこと:**
- `create_service()` でサービス登録、コールバックで request → response を返す
- `create_client()` + `wait_for_service()` + `call_async()` のクライアントパターン
- Service = I2C のレジスタ読み書きに相当（呼んだら返ってくる同期パターン）

#### 4. Action（Goal + Feedback + Result）
- `my_interfaces` パッケージ作成（`ament_cmake`）— カスタム `.action` 定義用
- `Countdown.action`: target_number(Goal) → current_number(Feedback) → final_message(Result)
- `countdown_server.py`: ActionServer でカウントダウン実行、毎秒フィードバック送信
- `countdown_client.py`: ActionClient でゴール送信、フィードバック受信、結果取得
- 動作確認: 5からカウントダウン、フィードバック5→4→3→2→1、"Countdown complete!" 成功

**学んだこと:**
- Action = 長時間タスク + 途中経過通知 + キャンセル可能
- カスタムインターフェースは `ament_cmake` パッケージ + `rosidl_generate_interfaces` で生成
- Action = DMA バックグラウンド転送 + 進捗割り込み + 完了通知 に相当

### 作成したファイル（WSL2 Ubuntu 22.04 内）

```
~/ros2_ws/
├── src/
│   ├── my_first_pkg/           # ament_python パッケージ
│   │   ├── my_first_pkg/
│   │   │   ├── hello_publisher.py
│   │   │   ├── hello_subscriber.py
│   │   │   ├── add_two_ints_server.py
│   │   │   ├── add_two_ints_client.py
│   │   │   ├── countdown_server.py
│   │   │   └── countdown_client.py
│   │   ├── setup.py
│   │   └── package.xml
│   └── my_interfaces/          # ament_cmake パッケージ（カスタムインターフェース）
│       ├── action/
│       │   └── Countdown.action
│       ├── CMakeLists.txt
│       └── package.xml
```

### ROS 2 通信パターン比較

| パターン | 方向 | 用途 | FW例え |
|---------|------|------|--------|
| Topic (Pub/Sub) | 一方通行・非同期 | センサデータ配信 | UART 垂れ流し |
| Service (Req/Res) | 双方向・同期的 | 短時間コマンド | I2C レジスタ読み書き |
| Action (Goal/FB/Result) | 双方向・非同期 | 長時間タスク | DMA転送+割り込み通知 |

### 残タスク
- [x] RViz2 でデータ可視化 (2025-02-27)
- [x] URDF でロボットモデル記述 (2025-02-27)
- [x] TF2 座標変換 (2025-02-27)
- [x] Launch ファイル (2025-02-27)
- [ ] turtlesim 統合演習（オプション）

---

## 2025-02-27: Day 1 (続) — URDF + TF2 + Launch + RViz2

### 実施内容

#### 5. URDF ロボットモデル
- `my_robot_description` パッケージを作成（`ament_python`）
- `my_robot.urdf`: 差動駆動ロボット（2輪 + キャスター + カメラ + LiDAR）
- link（部品）と joint（接続）でロボットの機械構造を記述
- KiCad の回路図がEE構造を記述するのと同様、URDF はME構造を記述

**URDFの構造:**
```
base_link (青い箱: 30x20x10cm)
├── left_wheel (黒い円柱: continuous joint = 回転軸)
├── right_wheel (黒い円柱: continuous joint)
├── caster (灰色の球: fixed joint = 固定)
├── camera_link (赤い箱: fixed, 前方+15cm, 上方+8cm)
└── lidar_link (緑の円柱: fixed, 上方+12cm)
```

#### 6. TF2 座標変換
- `odom_broadcaster.py`: TransformBroadcaster で odom → base_link の動的変換を配信
- ロボットが半径1mの円を描いて移動するシミュレーション（20Hz）
- robot_state_publisher が URDF から静的変換（base_link → camera_link 等）を自動配信

**学んだこと:**
- **Static Transform**: URDFのfixed jointから自動生成。センサーの基板上での固定位置に相当
- **Dynamic Transform**: odom_broadcaster で配信。エンコーダから算出する現在位置に相当
- yaw角 → quaternion 変換: `z = sin(θ/2)`, `w = cos(θ/2)`

**TF2 フレームツリー:**
```
odom (世界座標系)
└── base_link (ロボット本体) ← 動的: 20Hzで位置更新
    ├── left_wheel        ← 静的: URDFから自動
    ├── right_wheel       ← 静的
    ├── caster            ← 静的
    ├── camera_link       ← 静的: +15cm前方, +8cm上方
    └── lidar_link        ← 静的: +12cm上方
```

#### 7. Launch ファイル
- `display_robot.launch.py`: 3ノードを一括起動
  1. `robot_state_publisher` — URDF → TF2 静的変換
  2. `odom_broadcaster` — 擬似オドメトリ（動的変換）
  3. `rviz2` — 3D可視化
- `data_files` で urdf/, launch/, rviz/ をインストール先に含める
- `ament_index_python.packages.get_package_share_directory()` でパッケージパスを取得

**学んだこと:**
- Launch = FW の `main()` 初期化シーケンス。全ノードを宣言的に起動
- `with open(urdf_file)` で URDF を読み込み、`robot_description` パラメータとして渡す
- RViz2 の `.rviz` 設定ファイルで表示項目を事前設定

#### 8. RViz2 可視化
- RobotModel（URDFの3D表示）、TF（座標フレームの矢印表示）、Grid を設定
- Fixed Frame = `odom` に設定（世界座標系を基準に表示）

### 作成したファイル

```
~/ros2_ws/src/my_robot_description/
├── urdf/my_robot.urdf              ← ロボットの機械設計図
├── my_robot_description/
│   └── odom_broadcaster.py         ← TF2 動的変換（擬似オドメトリ）
├── launch/display_robot.launch.py  ← 全ノード一括起動
├── rviz/robot.rviz                 ← RViz2 表示設定
├── setup.py
└── package.xml
```

### 起動コマンド
```bash
ros2 launch my_robot_description display_robot.launch.py
```

### WSLg トラブルシュート
- RViz2 起動時に一瞬ブラックアウトしてクラッシュ → RTX 5070 の OpenGL ドライバと WSLg の相性問題
- **解決策**: `export LIBGL_ALWAYS_SOFTWARE=1` でソフトウェアレンダリングに切り替え
- `~/.bashrc` に追加して恒久化済み
- `xclock` で WSLg 自体の動作確認は OK だった
- ソフトウェアレンダリングではフレーム飛びが発生するが学習目的では問題なし

### Week 1-2 進捗サマリー
- チェックリスト: 16/21 完了（76%）
- 残り: rqt_graph, geometry_msgs, QoS, パラメータYAML, ros2 bag
- これらは Week 3-4（Gazebo + SLAM + Nav2）の実践の中で自然に使うため、先に進む予定
