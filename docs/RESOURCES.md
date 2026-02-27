# Physical AI 学習リソース集

> Physical AI エンジニアを目指すための包括的な学習リソース集。
> リンクは2025〜2026年時点で有効なものを掲載。「（要確認）」マーク付きURLは変更の可能性あり。
> 難易度表記: [入門] [中級] [上級]

---

## 目次

1. [ROS 2](#1-ros-2)
2. [マルチモーダルAI / VLM](#2-マルチモーダルai--vlm)
3. [ロボティクス基礎](#3-ロボティクス基礎)
4. [フィジカルAI関連](#4-フィジカルai関連)
5. [論文・技術ブログ](#5-論文技術ブログ)
6. [オンラインコース・動画](#6-オンラインコース動画)
7. [コミュニティ・情報源](#7-コミュニティ情報源)
8. [開発ツール・データセット・書籍](#8-開発ツールデータセット書籍)

---

## 1. ROS 2

### 1.1 公式ドキュメント・チュートリアル

#### ROS 2 Humble 公式チュートリアル [入門]
- **URL:** https://docs.ros.org/en/humble/Tutorials.html
- **概要:** インストールからトピック、サービス、アクションまで網羅
- **推奨学習順序:**
  1. CLI Tools チュートリアル（turtlesim を使った基礎）
  2. Client Libraries（rclpy / rclcpp の基本）
  3. Intermediate（Launch ファイル、パラメータ管理）
  4. Advanced（カスタムメッセージ、アロケータ設定）
- **学習時間目安:** 2〜3週間（1日1〜2時間）

#### ROS 2 Design Documents [上級]
- **URL:** https://design.ros2.org/
- **概要:** アーキテクチャ設計思想、DDS の選定理由、QoS ポリシー等
- **重要文書:** Topic/Service Name Mapping, ROS on DDS, Clock/Time design, Actions design

### 1.2 学習プラットフォーム

#### The Construct [入門〜中級]
- **URL:** https://www.theconstructsim.com/
- **概要:** ブラウザ上で ROS 2 を学べるプラットフォーム（環境構築不要）
- **推奨コース:** ROS 2 Basics in 5 Days, ROS 2 Navigation, ROS 2 Manipulation

### 1.3 主要パッケージ・フレームワーク

#### ros2_control [中級]
- **URL:** https://control.ros.org/
- **概要:** ロボット制御の標準フレームワーク
- **学習内容:** Hardware Interface, Controller Manager, Joint Trajectory Controller
- **ファームウェアとの関連:** HAL設計と類似、リアルタイム制御ループの概念が活かせる

#### Navigation 2 (Nav2) [中級]
- **URL:** https://docs.nav2.org/
- **概要:** 自律ナビゲーションフレームワーク
- **主要コンポーネント:** Planner Server, Controller Server, Behavior Server, Costmap, BT Navigator

#### MoveIt 2 [中級〜上級]
- **URL:** https://moveit.ros.org/
- **概要:** モーションプランニングフレームワーク
- **学習内容:** Setup Assistant, Motion Planning Pipeline, Servo, Perception Pipeline

#### micro-ROS [中級]
- **URL:** https://micro.ros.org/
- **概要:** マイクロコントローラ上で動作する ROS 2 クライアント（ESP32, STM32, RPi Pico）
- **ファームウェアとの関連:** 組み込みとROS 2の橋渡し、RTOS上での動作

### 1.4 重要パッケージ一覧

| パッケージ | 用途 | 優先度 |
|---|---|---|
| `rclpy` | Python クライアントライブラリ | 最高 |
| `rclcpp` | C++ クライアントライブラリ | 高 |
| `sensor_msgs` | センサーデータ（Image, LaserScan, Imu 等） | 最高 |
| `geometry_msgs` | 幾何学メッセージ（Pose, Twist, Transform 等） | 最高 |
| `nav_msgs` | ナビゲーション（OccupancyGrid, Path 等） | 高 |
| `tf2_ros` | 座標変換フレームワーク | 最高 |
| `std_msgs` | 標準メッセージ型 | 高 |
| `image_transport` | 画像配信の最適化 | 高 |
| `cv_bridge` | OpenCV と ROS 2 画像の変換 | 高 |
| `robot_state_publisher` | ロボットモデル（URDF）配信 | 高 |
| `rviz2` | 3D 可視化ツール | 最高 |
| `rosbag2` | データ記録・再生 | 中 |

### 1.5 GitHub リソース

- **Awesome ROS 2** [入門]: https://github.com/fkromer/awesome-ros2
  - ROS 2 関連のリソース、パッケージ、ツールの包括的リスト
- **TurtleBot3 パッケージ** [入門]: https://github.com/ROBOTIS-GIT/turtlebot3
  - Nav2 や SLAM の学習に最適
- **ros2/examples** [入門〜中級]: https://github.com/ros2/examples
  - 公式サンプルコード集

---

## 2. マルチモーダルAI / VLM

### 2.1 主要 VLM モデル

#### LLaVA [中級]
- **URL:** https://huggingface.co/liuhaotian/llava-v1.6-mistral-7b （要確認）
- **概要:** 画像とテキストを統合的に理解するVLM（NeurIPS 2023）
- **特徴:** オープンソース、7Bパラメータで軽量、Mistralベース
- **ロボティクス応用:** シーン理解、物体検出と空間推論

#### CogVLM [中級]
- **URL:** https://huggingface.co/THUDM/cogvlm-chat-hf （要確認）
- **開発:** 清華大学 (THUDM)
- **特徴:** 高精度画像理解、Grounding機能、多言語対応

#### Florence-2 [中級]
- **URL:** https://huggingface.co/microsoft/Florence-2-large （要確認）
- **開発:** Microsoft
- **特徴:** コンパクト、Zero-shot性能が高い、Caption/Detection/Segmentation統一処理
- **Edge向き:** Jetson での推論に適したサイズ

#### Qwen-VL シリーズ [中級]
- **URL:** https://huggingface.co/Qwen （要確認）
- **開発:** Alibaba Cloud
- **バージョン:** Qwen-VL, Qwen-VL-Chat, Qwen2-VL
- **特徴:** 中国語・英語・日本語に強い、高解像度対応

#### InternVL シリーズ [中級]
- **URL:** https://huggingface.co/OpenGVLab （要確認）
- **開発:** Shanghai AI Laboratory
- **特徴:** SOTA レベル性能、スケーラブル、動的解像度対応

### 2.2 推論最適化

#### NVIDIA TensorRT [中級〜上級]
- **URL:** https://developer.nvidia.com/tensorrt
- **概要:** GPU向け高性能推論エンジン
- **学習内容:** モデル変換、量子化（INT8, FP16）、Dynamic Shape、TensorRT-LLM
- **ファームウェアとの関連:** ハードウェアレベルの最適化知識が活きる

#### ONNX Runtime [中級]
- **URL:** https://onnxruntime.ai/
- **概要:** クロスプラットフォーム推論エンジン（CPU/GPU/NPU対応）

#### vLLM [中級]
- **URL:** https://vllm.ai/
- **概要:** 高スループットLLM推論エンジン（PagedAttention、OpenAI互換API）

#### llama.cpp [中級]
- **URL:** https://github.com/ggerganov/llama.cpp
- **概要:** CPU/GPUでLLMを効率的に動作させるC++実装
- **ファームウェアとの関連:** C++実装で低レベル最適化の知見が活かせる、ローカルLLMデプロイの経験と直結

### 2.3 音声認識・マルチモーダル入力

#### OpenAI Whisper [入門〜中級]
- **URL:** https://github.com/openai/whisper
- **概要:** 高精度音声認識モデル（多言語・日本語対応、MITライセンス）
- **サイズ:** tiny〜large / 軽量版: whisper.cpp, faster-whisper
- **ロボティクス応用:** 音声コマンドによるロボット操作

#### Hugging Face Transformers [入門〜上級]
- **URL:** https://huggingface.co/docs/transformers
- **学習内容:** Pipeline API, AutoModel/AutoTokenizer, ファインチューニング, PEFT, マルチモーダル

### 2.4 NVIDIA Jetson エコシステム

#### Jetson プラットフォーム
- **URL:** https://developer.nvidia.com/embedded-computing
- **デバイス:** Orin Nano (40 TOPS), Orin NX (70-100 TOPS), AGX Orin (200-275 TOPS)
- **ファームウェアとの関連:** SBCデプロイ経験、電力最適化、ペリフェラル制御

#### 関連リソース
- **Jetson Containers:** https://github.com/dusty-nv/jetson-containers （要確認）
  - Docker コンテナ集（PyTorch, TensorRT, ROS 2, VLM等）
- **jetson-inference:** https://github.com/dusty-nv/jetson-inference （要確認）
  - Jetson でのDL推論入門（画像分類、物体検出、セグメンテーション）

---

## 3. ロボティクス基礎

### 3.1 逆運動学（Inverse Kinematics）

#### 教科書

**Robotics, Vision and Control (Peter Corke)** [中級]
- ロボティクスの基礎をMATLAB/Pythonで学べる包括的教科書
- 重要章: Robot Arm Kinematics, Velocity Kinematics, Motion Planning
- Python Toolbox: https://github.com/petercorke/robotics-toolbox-python （要確認）

**Modern Robotics (Kevin Lynch & Frank Park)** [中級〜上級]
- **URL:** https://modernrobotics.northwestern.edu/ （要確認）
- 無料公開、スクリュー理論ベース、Coursera動画講義あり
- 重要章: Forward/Inverse Kinematics, Dynamics, Trajectory Generation

#### 実装リソース
- **IKPy:** https://github.com/Phylliade/ikpy （要確認） - URDF対応Python逆運動学ライブラリ
- **KDL:** Open Source Robotics Foundation管理の運動学ライブラリ（`kdl_parser`でROS 2統合）

### 3.2 SLAM

#### 理論的背景

**Probabilistic Robotics (Sebastian Thrun 他)** [上級]
- SLAM、確率的状態推定の理論的基盤
- 重要章: Gaussian Filters, Nonparametric Filters, SLAM各手法

**Visual SLAM** [中級]
- "14 Lectures on Visual SLAM" (高翔 著)
- ORB-SLAM3: https://github.com/UZ-SLAMLab/ORB_SLAM3 （要確認）

#### ROS 2 対応 SLAM パッケージ

| パッケージ | 手法 | 入力 | URL |
|---|---|---|---|
| slam_toolbox | 2D Graph SLAM | LiDAR | https://github.com/SteveMacenski/slam_toolbox |
| rtabmap_ros | Visual+LiDAR 3D | Camera, LiDAR | （要確認） |
| cartographer_ros | 2D/3D Graph SLAM | LiDAR, IMU | （要確認） |

### 3.3 ロボット制御基礎

#### PID 制御 [入門]
- 最も基本的なフィードバック制御。ファームウェアでのモーター制御経験が直結。
- ROS 2: ros2_controllers パッケージ

#### モーションプランニング [中級]
- 主要アルゴリズム: RRT, RRT*, PRM, A*/Dijkstra, DWA
- ROS 2: Nav2 Planner Server, MoveIt 2

#### 制御理論 [中級]
- 古典制御（ボード線図、根軌跡法）、現代制御（LQR）、適応制御

### 3.4 シミュレーション環境

#### Gazebo (Gz) [入門〜中級]
- **URL:** https://gazebosim.org/
- ROS 2 標準シミュレータ。SDF定義、プラグイン開発、ros_gz_bridge

#### URDF / Xacro [入門]
- ロボットモデル記述（リンク、ジョイント、ビジュアル、コリジョン定義）

---

## 4. フィジカルAI関連

### 4.1 NVIDIA フィジカルAIプラットフォーム

#### NVIDIA Cosmos [中級〜上級]
- **URL:** https://developer.nvidia.com/cosmos
- 物理世界を理解するWorld Foundation Models
- 物理法則ベースの映像生成、合成データ生成、Sim-to-Realギャップ縮小

#### NVIDIA Omniverse [中級]
- **URL:** https://developer.nvidia.com/omniverse
- 3DワークフローのためのプラットフォームISO（Digital Twin構築、PhysX、レイトレーシング）
- Isaac Sim のベースプラットフォーム

#### NVIDIA Isaac Sim [中級〜上級]
- **URL:** https://developer.nvidia.com/isaac-sim
- ロボティクス特化の高忠実度シミュレータ
- 特徴: フォトリアリスティック、ROS 2ネイティブ統合、Domain Randomization
- 学習: セットアップ、URDF/USDインポート、センサーシミュレーション、ROS 2 Bridge
- 要件: NVIDIA RTX GPU（最低 RTX 3070 推奨）

#### NVIDIA Isaac ROS [中級]
- **URL:** https://developer.nvidia.com/isaac-ros
- GPUアクセラレーションされたROS 2パッケージ群
- 主要: Visual SLAM, DNN Inference, Object Detection, Nvblox
- Jetson Orin 最適化、NITROS高速データ転送

#### Isaac Lab (旧 Orbit) [上級]
- **URL:** https://isaac-sim.github.io/IsaacLab/ （要確認）
- Isaac Sim上での強化学習・模倣学習フレームワーク（GPU並列シミュレーション、Sim-to-Real転移）

### 4.2 ロボットプラットフォーム

#### Unitree Robotics [中級]
- **URL:** https://github.com/unitreerobotics （要確認）
- 主要製品: Go2（小型四足）, B2（産業用四足）, H1/G1（ヒューマノイド）
- SDK: unitree_sdk2 (C++/Python), unitree_ros2 (ROS 2ラッパー)
- 学習: ハイレベル/ローレベル制御、カスタムコントローラ

#### Unitree ROS 2 パッケージ [中級]
- **URL:** https://github.com/unitreerobotics/unitree_ros2 （要確認）
- URDF モデル、Gazebo設定、ROS 2制御インターフェース

### 4.3 日本のフィジカルAI企業

#### V-Sido OS
- ロボット用リアルタイムOS（ヒューマノイド全身協調制御、リアルタイム逆運動学）

---

## 5. 論文・技術ブログ

### 5.1 必読論文

#### RT-2: Vision-Language-Action Models Transfer Web Knowledge to Robotic Control [上級]
- **著者:** Google DeepMind (Anthony Brohan et al.) / **年:** 2023
- **URL:** https://arxiv.org/abs/2307.15818
- **概要:** VLMをロボット制御に直接活用。VLAモデルの提案、ウェブデータからの知識転移。

#### RT-1: Robotics Transformer for Real-World Control at Scale [上級]
- **著者:** Google DeepMind (Anthony Brohan et al.) / **年:** 2022
- **URL:** https://arxiv.org/abs/2212.06817
- **概要:** 大規模実世界データでのロボット制御トランスフォーマー（13万+デモ）

#### Octo: An Open-Source Generalist Robot Policy [上級]
- **著者:** UC Berkeley (Dibya Ghosh et al.) / **年:** 2024
- **URL:** https://arxiv.org/abs/2405.12213 （要確認）
- **概要:** オープンソース汎用ロボットポリシー。Open X-Embodimentデータセットで学習。

#### Open X-Embodiment: Robotic Learning Datasets and RT-X Models [上級]
- **著者:** Open X-Embodiment Collaboration / **年:** 2024
- **URL:** https://arxiv.org/abs/2310.08864
- **概要:** 22ロボットのデータ統合、クロスロボット転移学習、RT-Xモデル。

#### SayCan: Do As I Can, Not As I Say [上級]
- **著者:** Google Research (Michael Ahn et al.) / **年:** 2022
- **URL:** https://arxiv.org/abs/2204.01691
- **概要:** LLMの知識をロボットのaffordanceでグラウンディング。長期タスク分解。

#### PaLM-E: An Embodied Multimodal Language Model [上級]
- **著者:** Google Research (Danny Driess et al.) / **年:** 2023
- **URL:** https://arxiv.org/abs/2303.03378
- **概要:** 562Bパラメータの身体性マルチモーダル言語モデル。ロボットセンサーデータ直接入力。

#### CLIPort: What and Where Pathways for Robotic Manipulation [上級]
- **著者:** UW (Mohit Shridhar et al.) / **年:** 2022
- **URL:** https://arxiv.org/abs/2109.12098
- **概要:** CLIP + TransporterNet。言語指示による操作、少数デモでの学習。

#### Inner Monologue: Embodied Reasoning through Planning with Language Models [上級]
- **著者:** Google Research (Wenlong Huang et al.) / **年:** 2022
- **URL:** https://arxiv.org/abs/2207.05608
- **概要:** LLMの内部独白によるロボットの閉ループ推論。エラー回復能力。

#### Mobile ALOHA [上級]
- **著者:** Stanford (Zipeng Fu et al.) / **年:** 2024
- **URL:** https://arxiv.org/abs/2401.02117 （要確認）
- **概要:** 低コスト全身遠隔操作による双腕モバイルマニピュレーション学習。

#### DROID: A Large-Scale In-The-Wild Robot Manipulation Dataset [上級]
- **著者:** Columbia University et al. / **年:** 2024
- **URL:** https://arxiv.org/abs/2403.12945 （要確認）
- **概要:** 76,000+デモンストレーション、564シーン、86タスクの大規模データセット。

### 5.2 技術ブログ

- **NVIDIA Technical Blog** [中級]: https://developer.nvidia.com/blog/
  - 注目カテゴリ: Robotics, Generative AI, Edge Computing
- **Google DeepMind Blog** [上級]: https://deepmind.google/research/
  - RT-2, SayCan, PaLM-E等の解説
- **Hugging Face Blog** [中級]: https://huggingface.co/blog
  - VLM関連技術解説、モデルリリース情報
- **The Robot Report** [入門〜中級]: https://www.therobotreport.com/
  - ロボティクス業界ニュース

---

## 6. オンラインコース・動画

### 6.1 NVIDIA DLI (Deep Learning Institute) [中級]
- **URL:** https://www.nvidia.com/en-us/training/
- 推奨: AI on Jetson Nano, Real-Time Video AI, Fundamentals of Deep Learning
- 実際のGPU環境でのハンズオン、修了証書取得可能

### 6.2 Coursera

#### Modern Robotics Specialization [中級〜上級]
- **提供:** Northwestern University
- **URL:** https://www.coursera.org/specializations/modernrobotics （要確認）
- 6コース構成: Robot Motion → Kinematics → Dynamics → Planning → Manipulation → Capstone
- 教科書 Modern Robotics と連動

#### Self-Driving Cars Specialization [中級]
- **提供:** University of Toronto
- **URL:** https://www.coursera.org/specializations/self-driving-cars （要確認）
- 関連内容: 状態推定、ビジュアルパーセプション、モーションプランニング

### 6.3 Stanford 大学公開講義

- **CS237B: Principles of Robot Autonomy II** [上級]
  - URL: https://web.stanford.edu/class/cs237b/ （要確認）
  - 知覚、意思決定、学習ベース制御、安全性
- **CS231n: Deep Learning for Computer Vision** [中級〜上級]
  - URL: https://cs231n.stanford.edu/ （要確認）
  - VLMの基盤となる画像認識技術

### 6.4 YouTube チャンネル

#### ROS 2 学習向け
- **Articulated Robotics:** https://www.youtube.com/@ArticulatedRobotics （要確認）
- **The Construct:** ROS 2 関連動画多数
- **Robotics Back-End:** https://www.youtube.com/@RoboticsBackEnd （要確認）

#### AI・ロボティクス全般
- **Yannic Kilcher:** https://www.youtube.com/@YannicKilcher （要確認） - AI論文解説
- **Two Minute Papers:** AI研究の簡潔な紹介
- **NVIDIA Developer:** https://www.youtube.com/@NVIDIADeveloper

### 6.5 edX [中級]
- Robot Mechanics and Control (Seoul National University) （要確認）
- Autonomous Mobile Robots (ETH Zurich) （要確認）
- Robotics MicroMasters (University of Pennsylvania) （要確認）

---

## 7. コミュニティ・情報源

### 7.1 フォーラム

- **ROS Discourse** [入門〜上級]: https://discourse.ros.org/
  - ROS公式フォーラム。技術Q&A、リリースノート、パッケージ告知
- **NVIDIA Developer Forums** [中級]: https://forums.developer.nvidia.com/
  - Jetson、Isaac Sim/ROS、TensorRTの技術サポート
- **r/robotics (Reddit)** [入門]: https://www.reddit.com/r/robotics/
  - 関連: r/ROS, r/reinforcementlearning, r/computervision
- **Hugging Face Community** [入門〜中級]: https://discuss.huggingface.co/
  - モデル利用のQ&A、ファインチューニングノウハウ

### 7.2 日本語コミュニティ

- **ROS Japan Users Group:** connpass で「ROS」「ROS 2」検索
- **日本ロボット学会 (RSJ):** https://www.rsj.or.jp/
- **Qiita:** https://qiita.com/ - ROS 2、ロボティクス記事充実
- **Zenn:** https://zenn.dev/ - 技術記事・本のプラットフォーム

### 7.3 カンファレンス

- **ROSCon:** ROSコミュニティ最大。過去動画YouTube公開。ROSCon JP あり
- **NVIDIA GTC:** https://www.nvidia.com/gtc/ - Robotics, Physical AI, Isaac セッション
- **ICRA:** ロボティクス分野トップカンファレンス
- **CoRL:** ロボット学習特化カンファレンス

---

## 8. 開発ツール・データセット・書籍

### 8.1 開発ツール

#### コンテナ・仮想化
- **Docker + ROS 2:** https://hub.docker.com/_/ros （要確認）
- **Dev Containers (VS Code):** ホストを汚さずにROS 2開発可能

#### 可視化ツール
- **RViz 2:** ROS 2標準3D可視化（URDF、センサーデータ、TF、地図）
- **PlotJuggler:** https://github.com/facontidavide/PlotJuggler （要確認） - リアルタイムプロット
- **Foxglove Studio:** https://foxglove.dev/ - Webベース可視化、モダンUI

#### ハードウェア設計
- **KiCad:** https://www.kicad.org/ - オープンソースEDA
  - 既存のKiCad経験をロボット用カスタムボード設計に応用

### 8.2 データセット

#### ロボット操作データセット

| データセット | 規模 | URL |
|---|---|---|
| Open X-Embodiment | 1M+ episodes, 22ロボット | https://robotics-transformer-x.github.io/ （要確認） |
| DROID | 76K+ demos, 564シーン | （要確認） |
| RoboSet | 100K+ trajectories | （要確認） |
| BridgeData V2 | 60K+ trajectories | （要確認） |

#### ビジョン・言語ベンチマーク

| ベンチマーク | 評価対象 |
|---|---|
| COCO | 物体検出・セグメンテーション |
| VQA v2 | 視覚的質問応答 |
| GQA | 視覚的推論 |
| TextVQA | 画像中テキスト理解 |

#### シミュレーションベンチマーク

| ベンチマーク | 対象 | URL |
|---|---|---|
| BEHAVIOR-1K | 家庭内タスク | https://behavior.stanford.edu/ （要確認） |
| RLBench | マニピュレーション | https://github.com/stepjam/RLBench （要確認） |
| MetaWorld | マルチタスク | https://github.com/Farama-Foundation/Metaworld （要確認） |
| Habitat | 屋内ナビゲーション | https://aihabitat.org/ （要確認） |

### 8.3 書籍一覧

#### ロボティクス基礎

| 書名 | 著者 | レベル | 備考 |
|---|---|---|---|
| Robotics, Vision and Control | Peter Corke | 中級 | MATLAB/Python対応 |
| Modern Robotics | Kevin Lynch, Frank Park | 中級〜上級 | 無料PDF公開 |
| Probabilistic Robotics | Sebastian Thrun et al. | 上級 | SLAMの理論的基盤 |
| Introduction to Autonomous Mobile Robots | Roland Siegwart et al. | 中級 | 移動ロボットの基礎 |

#### AI・機械学習

| 書名 | 著者 | レベル | 備考 |
|---|---|---|---|
| Deep Learning | Ian Goodfellow et al. | 中級〜上級 | 無料オンライン版 |
| Dive into Deep Learning | Aston Zhang et al. | 中級 | インタラクティブ |
| Computer Vision: Algorithms and Applications | Richard Szeliski | 中級〜上級 | 無料PDF公開 |

#### ROS関連

| 書名 | 著者 | レベル |
|---|---|---|
| Programming Robots with ROS | Morgan Quigley et al. | 入門〜中級 |
| A Gentle Introduction to ROS | Jason O'Kane | 入門 |

---

## 付録: 推奨学習パス

#### フェーズ1: ROS 2 基礎（2〜3週間）
1. ROS 2 Humble 公式チュートリアル完走
2. TurtleBot3 シミュレーションで Nav2 を試す
3. 簡単なカスタムノードの作成

#### フェーズ2: AI・VLM 基礎（2〜3週間）
1. Hugging Face Transformers の基本操作
2. VLM モデル（LLaVA または Florence-2）の推論実行
3. Whisper での音声認識実験

#### フェーズ3: ロボティクス理論（2〜4週間）
1. Modern Robotics の主要章を学習
2. SLAM の基礎理論を理解
3. MoveIt 2 のチュートリアル実行

#### フェーズ4: 統合プロジェクト（4〜6週間）
1. Isaac Sim でのシミュレーション環境構築
2. VLM + ROS 2 の統合
3. ポートフォリオプロジェクトの完成

---

> **注意:** URL は定期的に有効性を確認してください。
> 「（要確認）」マークのあるリンクは変更されている可能性が高いです。
