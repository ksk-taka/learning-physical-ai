# Week 9-10: シミュレーション環境

## 概要

Week 9-10では、**NVIDIA Isaac Sim**を使ったロボットシミュレーション環境の構築と、
**強化学習（RL）の基礎**を学ぶ。Isaac SimはNVIDIAのPhysical AIプラットフォームの中核であり、
リアルな物理シミュレーション、センサーシミュレーション、そしてSim-to-Real転移を実現するツールである。

ファームウェアエンジニアとしてのセンサー知識と、Month 1-2で構築したROS 2 + AIの知見を活かし、
シミュレーション上でAI制御のロボットが動くデモを完成させることが2週間のゴールである。

---

## 学習目標

1. **NVIDIA Isaac Sim（Windows版）のセットアップ**と基本操作を習得する
2. **Isaac Simでのロボットシミュレーション**（環境構築、センサーシミュレーション、ドメインランダマイゼーション）ができる
3. **Sim-to-Real transfer**の概念を理解し、その重要性を説明できる
4. **強化学習（RL）の基礎**（報酬設計、PPO、簡単な歩行/把持タスク）を理解する
5. **到達目標**: Isaac Sim上でAI制御のロボットが動くデモを完成させる

---

## 前提知識の確認

### Month 1（ROS 2基盤）

- [ ] ROS 2 Humbleの基本操作（ノード起動、トピック確認、サービス呼び出し）
- [ ] Publisher/Subscriber、Service、Actionの実装経験
- [ ] tf2座標変換の概念理解と基本設定
- [ ] URDFによるロボットモデル記述、Gazeboシミュレーション、Nav2自律移動

### Month 2（AI統合）

- [ ] VLM（LLaVA等）のローカルデプロイと推論
- [ ] 物体検出パイプライン（YOLO等）、Whisper音声認識
- [ ] AI推論 → ROS 2ノード統合パイプラインの実装

### 基礎知識

- [ ] Python基本（クラス、関数）、PyTorch基本操作（テンソル、forward pass）
- [ ] ロボットのキネマティクス・ダイナミクスの基本（Month 1のURDF作業から）

---

## 推奨学習順序

### Day 1-3: Isaac Sim セットアップと基礎

#### Day 1: Omniverse Launcherのインストール

Isaac SimはNVIDIA Omniverseプラットフォームの一部として提供される。
WindowsネイティブでIsaac Simを動かし、ROS 2はWSL2上で実行する構成を取る。

**インストール手順:**
1. NVIDIA Omniverse Launcher をダウンロード（https://www.nvidia.com/en-us/omniverse/download/）
2. 管理者権限でインストール、NVIDIAアカウントでサインイン
3. "Exchange"タブからIsaac Simをインストール（約10〜15GBのディスク容量が必要）
4. Omniverse Nucleusのセットアップ（オプション、USD資産管理用）
5. 初回起動、サンプルシーンで動作確認

**システム要件の確認:**

| 項目 | 要件 | 開発環境 | 判定 |
|------|------|---------|------|
| GPU | RTX 2070以上 | RTX 5070 (8GB) | 余裕で満たす |
| VRAM | 8GB以上推奨 | 8GB | 境界線（シーン複雑度に注意） |
| CPU | Core i7以上 | Core Ultra 9 275HX | 大幅に超過 |
| RAM | 32GB以上推奨 | — | Isaac Sim + WSL2で合計12〜24GB使用 |
| SSD | 30GB以上の空き | — | Isaac Sim + USD資産 + キャッシュ |

#### Day 2: Isaac Sim UIツアーと基本操作

**基本操作:**

| 操作 | マウス/キー | 操作 | マウス/キー |
|------|-----------|------|-----------|
| 視点回転 | Alt + 左ドラッグ | 移動モード | W キー |
| パン | Alt + 中ドラッグ | 回転モード | E キー |
| ズーム | Alt + 右ドラッグ | スケールモード | R キー |
| オブジェクト選択 | 左クリック | 物理再生 | Space |

**基本的なシーン作成（Script Editor）:**

```python
from omni.isaac.core import World
from omni.isaac.core.objects import DynamicCuboid

world = World()
world.scene.add_default_ground_plane()

cube = world.scene.add(
    DynamicCuboid(
        prim_path="/World/Cube", name="my_cube",
        position=[0, 0, 1.0], size=0.2, color=[1.0, 0.0, 0.0],
    )
)
world.reset()
world.step()
```

#### Day 3: USD (Universal Scene Description) の理解

Isaac SimはPixar社が開発したUSD形式をシーン記述の基盤として使用。

```
USD のデータ構造:
/World                          ← ルートプリム
├── /World/GroundPlane          ← 地面
├── /World/Robot                ← ロボット
│   ├── /World/Robot/base_link  ← ベースリンク
│   ├── /World/Robot/joint1     ← 関節
│   └── /World/Robot/camera     ← カメラセンサー
├── /World/Table                ← 環境オブジェクト
└── /World/Light                ← 照明
```

**USDの特徴（ファームウェア経験との対比）:**

| USD の概念 | ファームウェアでの対応概念 |
|-----------|------------------------|
| Prim（プリミティブ） | デバイスツリーのノード |
| Property（属性） | レジスタの設定値 |
| Reference（参照） | ヘッダファイルのinclude |
| Layer（レイヤー） | オーバーレイ設定（DTS overlay） |

---

### Day 4-6: ロボットシミュレーション

#### Day 4: ロボットモデルのインポート（URDF → USD変換）

```python
from omni.isaac.urdf import _urdf
from omni.isaac.core.utils.extensions import enable_extension

enable_extension("omni.isaac.urdf")
urdf_interface = _urdf.acquire_urdf_interface()

import_config = _urdf.ImportConfig()
import_config.merge_fixed_joints = False
import_config.fix_base = False          # モバイルロボットはFalse
import_config.import_inertia_tensor = True
import_config.default_drive_type = _urdf.UrdfJointTargetType.JOINT_DRIVE_POSITION
import_config.default_drive_strength = 1e4
import_config.default_position_drive_damping = 1e3

result = urdf_interface.parse_urdf("/path/to/robot.urdf", import_config)
urdf_interface.import_robot("/path/to/robot.urdf", "/World/Robot", import_config, "Z")
```

**変換時のよくある問題:**

| 問題 | 原因 | 対処法 |
|------|------|--------|
| メッシュ非表示 | パス参照の不一致 | 絶対パスに修正 |
| 関節が動かない | ドライブ設定の不備 | default_drive_typeを確認 |
| 物理挙動がおかしい | 慣性テンソルの問題 | import_inertia_tensorを確認 |
| スケールがおかしい | 単位系の不一致 | distance_scaleで調整 |

#### Day 5: センサーの追加とシミュレーション

ファームウェアエンジニアとしてのセンサー知識が最も活きる場面。

**Isaac Simで使用可能なセンサー:**

| カテゴリ | センサー | ROS 2メッセージ型 |
|---------|---------|-----------------|
| 視覚 | RGB Camera, Depth Camera, Stereo Camera | sensor_msgs/Image |
| 距離 | LiDAR（Velodyne, Ouster等のプリセット） | sensor_msgs/PointCloud2 |
| 慣性 | IMU（加速度、角速度、ノイズモデル設定可） | sensor_msgs/Imu |
| 接触 | Contact Sensor, Force/Torque | カスタムメッセージ |

```python
from omni.isaac.sensor import Camera, IMUSensor

# カメラの追加
camera = Camera(
    prim_path="/World/Robot/camera_link/rgb_camera",
    name="front_camera", frequency=30, resolution=(640, 480),
)
camera.initialize()
rgb_image = camera.get_rgb()

# IMUの追加（ファームウェアエンジニアに馴染みのあるセンサー）
imu = IMUSensor(
    prim_path="/World/Robot/base_link/imu_sensor",
    name="robot_imu", frequency=200,  # 実機と同等のレート
)
imu.initialize()
imu_data = imu.get_current_frame()
# linear_acceleration, angular_velocity, orientation が取得可能
```

**ファームウェアエンジニアへの補足**: 実機のセンサードライバ開発で扱ってきた物理量が
シミュレーション上で再現される。ノイズモデルのパラメータは実機のデータシートと同じ概念
（ホワイトノイズ、バイアス、ドリフト等）。

#### Day 6: ROS 2 Bridge（Isaac Sim ↔ ROS 2の接続）

```
  Windows 11                           WSL2 (Ubuntu 22.04)
  ┌────────────────────┐              ┌────────────────────┐
  │  Isaac Sim          │  DDS/UDP    │  ROS 2 Humble      │
  │  ┌──────────────┐  │◄──────────►│  ┌──────────────┐  │
  │  │ ROS2 Bridge  │  │ (localhost) │  │ rviz2, nav2  │  │
  │  │ Extension    │  │             │  │ AI nodes     │  │
  │  └──────────────┘  │             │  └──────────────┘  │
  └────────────────────┘              └────────────────────┘
```

**セットアップ手順:**
1. Isaac Simで拡張機能を有効化: Window > Extensions > "omni.isaac.ros2_bridge"
2. Action Graphでパブリッシャー構成: "On Playback Tick" + "ROS2 Camera Helper" + "ROS2 Publish Clock"
3. WSL2側で環境変数設定: `export ROS_DOMAIN_ID=0`
4. 動作確認: `ros2 topic list` でトピックが見えれば成功

**WSL2側でのネットワーク設定:**

```bash
# WSL2のIPアドレス確認
ip addr show eth0
# DDS通信のための環境変数（~/.bashrc に追加）
export ROS_DOMAIN_ID=0
export FASTRTPS_DEFAULT_PROFILES_FILE=~/fastrtps_profile.xml
# 注意: Windowsファイアウォールで UDP 7400-7500 の許可が必要な場合がある
```

---

### Day 7-9: ドメインランダマイゼーション & Sim-to-Real

#### Day 7-8: ドメインランダマイゼーション

シミュレーション環境のパラメータをランダムに変動させ、AIの汎化性能を高める手法。

**ファームウェアエンジニアへの説明**: EMC試験で様々なノイズ環境下の動作を検証し、
環境試験で温度・湿度・振動を変えて検証し、量産テストで部品バラツキを考慮するのと
同じ考え方をAIの学習に適用する。

| カテゴリ | パラメータ例 | 方法 |
|---------|-------------|------|
| 照明 | 光源の位置、強度、色温度 | 一様分布で変動 |
| テクスチャ | 床、壁、物体の表面 | セットからランダム選択 |
| カメラ | 露出、ホワイトバランス、レンズ歪み | ガウス分布でノイズ付加 |
| 物理 | 摩擦係数、反発係数、質量 | 範囲内でランダムサンプリング |
| 配置 | 物体の位置、向き、個数 | 範囲内でランダム配置 |

```python
import omni.replicator.core as rep

with rep.trigger.on_frame():
    # 照明のランダマイゼーション
    with rep.create.light(light_type="distant",
        temperature=rep.distribution.uniform(3000, 8000),
        intensity=rep.distribution.uniform(500, 2000)):
        rep.modify.pose(rotation=rep.distribution.uniform((-180,-90,0), (180,90,0)))

    # テクスチャのランダマイゼーション
    floor = rep.get.prims(path_pattern="/World/GroundPlane")
    with floor:
        rep.randomizer.texture(textures=[
            "omniverse://localhost/NVIDIA/Materials/Base/Wood/",
            "omniverse://localhost/NVIDIA/Materials/Base/Concrete/",
        ])

    # 物体配置のランダマイゼーション
    objects = rep.get.prims(semantics=[("class", "target_object")])
    with objects:
        rep.modify.pose(
            position=rep.distribution.uniform((-1,-1,0.5), (1,1,1.5)),
            rotation=rep.distribution.uniform((0,0,0), (360,360,360)))
```

#### Day 9: Sim-to-Real Transferの概念理解

```
Sim-to-Real パイプライン:

  1. シミュレーション環境構築（ロボット、環境、センサーモデル）
     ↓
  2. ドメインランダマイゼーション（照明、テクスチャ、物理パラメータ変動）
     ↓
  3. 学習・評価（RL でポリシー学習 / 合成データで認識モデル学習）
     ↓
  4. Sim-to-Real Transfer（実機転送、Reality Gap分析、Fine-tuning）
```

**Sim-to-Real手法の比較:**

| 手法 | 概要 | 長所 | 短所 |
|------|------|------|------|
| Domain Randomization | パラメータをランダム化 | 実装が容易 | 非効率な場合あり |
| Domain Adaptation | シムと実データの分布を揃える | 効率的な転移 | 実機データが必要 |
| Real2Sim | 実環境をスキャンしてシム化 | 高精度な環境再現 | スキャン工程が必要 |
| System Identification | 物理パラメータを実機合わせ | 物理挙動が正確 | パラメータ同定が困難 |

---

### Day 10-11: 強化学習の基礎

#### Day 10: RL基本概念

```
  ┌───────────┐     Action(a)     ┌───────────┐
  │  Agent    │ ─────────────────> │Environment│
  │(エージェント)│ <───────────────── │  (環境)    │
  └───────────┘  State(s), Reward(r)└───────────┘
```

| 用語 | 説明 | ロボティクスでの例 |
|------|------|------------------|
| State（状態） | 環境の現在の状態 | 関節角度、速度、センサー値 |
| Action（行動） | エージェントが取る行動 | モーターへのトルク指令 |
| Reward（報酬） | 行動の良し悪し | 目標に近づいたら+1、転倒したら-10 |
| Policy（方策） | 状態→行動の写像 | ニューラルネットワーク |
| MDP | マルコフ決定過程 | 状態空間、行動空間、遷移確率、報酬、割引率 |

**ファームウェアエンジニアへの補足**: 制御工学の「フィードバック制御」と概念が近い。
State = センサー値、Action = アクチュエータ指令、Reward = 制御誤差の逆。
RLはPID制御のゲインを自動チューニングする高度版と考えるとわかりやすい。

#### Day 11: PPO（Proximal Policy Optimization）

PPOがロボティクスRLで選ばれる理由:
- **安定性**: ポリシー更新幅を制限（クリッピング）し、学習が発散しにくい
- **サンプル効率**: 同じデータを複数回使って学習（ミニバッチ更新）
- **実装の容易さ**: Stable Baselines3等のライブラリで簡単に使える
- **汎用性**: 連続/離散行動空間、並列環境対応

**Isaac Lab でのRL実行（VRAM 8GB対応）:**

```bash
# 四足歩行ロボットの歩行学習（環境数を制限）
python source/standalone/workflows/rsl_rl/train.py \
  --task Isaac-Velocity-Rough-Anymal-C-v0 \
  --num_envs 64  # デフォルト4096→64に削減（8GB VRAM対応）

# 学習結果の確認
python source/standalone/workflows/rsl_rl/play.py \
  --task Isaac-Velocity-Rough-Anymal-C-v0 --num_envs 4
```

**報酬設計の例（把持タスク）:**

```python
def compute_reward(gripper_pos, target_pos, is_grasped, gripper_effort):
    distance = torch.norm(gripper_pos - target_pos, dim=-1)
    distance_reward = 1.0 / (1.0 + distance)      # 距離報酬
    grasp_reward = is_grasped.float() * 10.0        # 把持報酬
    effort_penalty = -0.01 * torch.sum(gripper_effort ** 2, dim=-1)  # エネルギーペナルティ
    return distance_reward + grasp_reward + effort_penalty

# ファームウェアエンジニアへの補足:
# 報酬設計 = 制御システムの「コスト関数」設計
# distance_reward ≒ 状態誤差コスト（LQRのQ行列）
# effort_penalty ≒ 入力コスト（LQRのR行列）
```

---

### Day 12-14: 統合プロジェクト

2週間の学習成果を統合し、**Isaac Sim上でAI制御のロボットが動くデモ**を構築する。

**デモのシナリオ案（選択）:**

| 選択肢 | 内容 | 重点 |
|--------|------|------|
| **A: ナビゲーション + 認識** | 室内環境でロボットがカメラ・LiDAR付きで自律移動、VLMで物体認識 | Month 1-2の統合 |
| **B: RL歩行デモ** | Isaac Labで四足歩行ロボットの歩行をPPOで学習、ドメインランダマイゼーション適用 | RL理解 |

**プロジェクト構成:**

```
week9-10-isaac-sim/
├── scenes/         # USDシーンファイル
├── robots/         # ロボットモデル（URDF→USD変換済み）
├── scripts/        # シーン構築、センサーテスト、ROS 2ブリッジ、RL学習スクリプト
└── results/        # 学習ログ、デモ動画
```

**Day 14**: デモの実行手順をドキュメント化、スクリーンショット・動画撮影、
Week 11-12のポートフォリオ制作に向けた素材整理。

---

## 練習課題

| # | ファイル | 目標 |
|---|---------|------|
| 01 | exercise01_isaac_sim_basics.md | Isaac Simの基本操作、シーン構築、物理シミュレーション再生 |
| 02 | exercise02_robot_import.md | URDFロボットをUSD変換、ジョイント制御 |
| 03 | exercise03_sensor_simulation.md | カメラ・LiDAR・IMUの追加とデータ取得 |
| 04 | exercise04_ros2_bridge.md | Isaac Sim ↔ ROS 2接続、rviz2での可視化 |
| 05 | exercise05_domain_randomization.md | 照明・テクスチャ・配置のランダマイゼーション |
| 06 | exercise06_rl_basics.md | Isaac Labでサンプルタスク実行、学習曲線の確認 |
| 07 | exercise07_integrated_demo.md | 全要素統合のデモ構築、動画録画 |

---

## 到達確認チェックリスト

### Isaac Sim 基礎
- [ ] Omniverse LauncherからIsaac Simをインストール・起動できる
- [ ] Isaac SimのUI操作（視点変更、オブジェクト配置、物理再生）ができる
- [ ] USDの基本概念（Prim、Property、Stage）を説明できる
- [ ] Pythonスクリプトでシーンを構築できる

### ロボットシミュレーション
- [ ] URDFからUSDへのロボットモデル変換ができる
- [ ] ロボットの関節制御（Position/Velocity/Effort）ができる
- [ ] RGB/Depthカメラ、LiDAR、IMUのシミュレーションデータを取得できる

### ROS 2連携
- [ ] Isaac Sim ↔ ROS 2 Bridgeが動作する
- [ ] センサーデータがROS 2トピックとして公開される
- [ ] WSL2上のrviz2でIsaac Simのデータを可視化できる
- [ ] cmd_velでIsaac Sim内のロボットを制御できる

### ドメインランダマイゼーション & Sim-to-Real
- [ ] ドメインランダマイゼーションの目的と手法を説明できる
- [ ] Isaac Simでランダマイゼーションを実装できる
- [ ] Sim-to-Real gapの主な要因を3つ以上説明できる

### 強化学習
- [ ] RLの基本用語（State、Action、Reward、Policy）を説明できる
- [ ] PPOアルゴリズムの基本的な仕組みを説明できる
- [ ] Isaac Labでサンプルタスクを実行し、学習結果を確認できる
- [ ] 簡単な報酬関数を設計できる

---

## つまずきやすいポイントと対処法

### 1. Isaac Simのパフォーマンス問題（RTX 5070 8GB VRAM）

**症状**: シーンが重い、フレームレートが低い、VRAM不足エラー

**対処法**:
- シーン複雑度を下げる（メッシュのポリゴン削減、テクスチャ512x512に）
- Path Tracingを避け、RTXリアルタイムレンダラーを使用
- RL学習時: `num_envs`を64〜256に制限、`--headless`モードで学習
- `nvidia-smi`でVRAM使用量を常時監視

### 2. Windows ↔ WSL2 ROS 2 Bridge ネットワーク問題

**症状**: Isaac Sim（Windows）からROS 2トピックがWSL2で見えない

**対処法**:
- 両方で`ROS_DOMAIN_ID`が一致しているか確認
- Windows Defenderファイアウォールで UDP 7400-7500を許可
- `.wslconfig`で`networkingMode=mirrored`を試す
- デバッグ: 両方で`ros2 topic list`を実行し、差分を確認

### 3. URDF → USD 変換の問題

**症状**: 変換後のロボットの見た目や挙動がおかしい

**対処法**:
- メッシュファイルのパスと単位系（m vs mm）を確認
- ジョイント軸の方向、リミット、ドライブパラメータ（stiffness/damping）を調整
- 質量・慣性テンソルの値を確認、必要に応じてPropertyパネルで手動修正

### 4. Isaac Lab バージョン互換性

**症状**: サンプルコードがエラーで動かない

**対処法**:
- Isaac SimとIsaac Labのバージョン対応表を公式ドキュメントで確認
- 仮想環境を新規作成し、公式手順に忠実にインストール
- 公式サンプルのみを使用する、またはDockerコンテナ版を試す

### 5. RL学習の不安定性

**症状**: 報酬が上がらない、学習が発散する

**対処法**:
- 報酬のスケールと各項目のバランスを見直す（個別にログ出力して分析）
- 学習率を下げる（1e-3 → 1e-4）、クリッピング範囲を調整
- 観測空間の正規化、行動空間のスケーリングを確認
- TensorBoardで学習曲線を可視化、少環境数でまず動作確認

### 6. Omniverse Nucleus・ディスク容量問題

**対処法**:
- Nucleusを使わず、USD資産をローカルファイルで管理する
- 事前に30〜50GBの空き容量を確保する
- Omniverse Cacheを定期的にクリアする

---

## 参考リンク

### NVIDIA Isaac Sim 公式

| リソース | URL |
|---------|-----|
| Isaac Sim 公式サイト | https://developer.nvidia.com/isaac-sim |
| Isaac Sim ドキュメント | https://docs.omniverse.nvidia.com/isaacsim/ |
| Isaac Lab (旧Orbit) | https://isaac-sim.github.io/IsaacLab/ |
| USD ドキュメント | https://openusd.org/release/index.html |

### 強化学習

| リソース | URL |
|---------|-----|
| Stable Baselines3 | https://stable-baselines3.readthedocs.io/ |
| Spinning Up (OpenAI) | https://spinningup.openai.com/ |
| CleanRL | https://github.com/vwxyzjn/cleanrl |

### 日本語リソース

| リソース | URL |
|---------|-----|
| NVIDIA日本語ブログ | https://blogs.nvidia.co.jp/ |
| Qiita (Isaac Sim タグ) | https://qiita.com/tags/isaacsim |
| Zenn (Isaac Sim) | https://zenn.dev/topics/isaacsim |
| ROS Japan Users Group | https://rosjp.connpass.com/ |

---

> **ファームウェアエンジニアの皆さんへ**: Isaac Simでのシミュレーションは、
> 組込み開発でのテスト環境構築と本質的に同じ考え方である。
> テスト治具を作り、さまざまな条件でデバイスの動作を検証するように、
> シミュレーション環境を構築し、多様な条件でロボットの動作を検証する。
> センサーのノイズ特性、物理法則への理解、テスト設計の経験は、
> ここで最大限に活かせる。自信を持って取り組んでほしい。
