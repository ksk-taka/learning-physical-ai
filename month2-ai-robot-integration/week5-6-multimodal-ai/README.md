# Week 5-6: マルチモーダル AI on エッジ

## 概要

Week 5-6 では、Vision-Language Model (VLM) と音声認識 (Whisper) を
RTX 5070 (8GB VRAM) のローカル環境で動かすことに集中します。

ROS 2 への統合は Week 7-8 で行うため、この 2 週間では AI モデルを
**単体で確実に動かせる**ことを最優先にします。

ファームウェアエンジニアとしての経験、特にローカル LLM デプロイの
経験は、このフェーズで大いに活きます。
テキストベースの LLM を動かした経験を、画像＋テキストのマルチモーダルモデルに
拡張していきましょう。

---

## 学習目標

1. **VLM (Vision-Language Model) の概要理解**
   - VLM のアーキテクチャと主要モデルの違いを説明できる
   - Physical AI における VLM の役割を理解する

2. **WSL2 + RTX 5070 環境で VLM を動かす**
   - LLaVA を量子化モデルで実行できる
   - VRAM 使用量を監視・制御できる

3. **カメラ画像 → VLM → テキスト出力パイプライン構築**
   - Web カメラからの画像取得
   - リアルタイムに近い推論パイプライン

4. **Whisper（音声認識）のローカル実行**
   - Whisper モデルの選択と実行
   - 日本語音声認識の実現

5. **到達目標**: カメラ画像を入力して物体や状況を自然言語で説明できるパイプラインが動作し、
   音声で質問を入力して VLM に問い合わせることができる

---

## 前提知識の確認

以下の知識があることを前提としています。不安な項目があれば、
先に復習してから進めてください。

### ニューラルネットワークの基礎

- [ ] 順伝播・逆伝播の基本概念
- [ ] CNN (畳み込みニューラルネットワーク) の基本構造
- [ ] Transformer アーキテクチャの概要（Attention 機構）
- [ ] 事前学習 (Pre-training) とファインチューニングの概念

> **復習リソース**: 3Blue1Brown の「Neural Networks」シリーズ (YouTube)、
> Andrej Karpathy の「Neural Networks: Zero to Hero」

### Python / PyTorch

- [ ] Python 3.10+ の基本文法
- [ ] NumPy 配列操作
- [ ] PyTorch テンソル操作 (torch.Tensor)
- [ ] PyTorch でのモデルロードと推論 (model.eval(), torch.no_grad())
- [ ] GPU への転送 (model.to("cuda"), tensor.cuda())

### ローカル LLM デプロイ経験

- [ ] Hugging Face Transformers ライブラリの使用経験
- [ ] モデルのダウンロードとロード
- [ ] 量子化の概念（ローカル LLM デプロイでの経験）
- [ ] VRAM 使用量の確認方法 (nvidia-smi)

### GPU メモリ管理

- [ ] VRAM と RAM の違い
- [ ] nvidia-smi コマンドの読み方
- [ ] CUDA バージョンの確認方法
- [ ] OOM (Out of Memory) エラーの対処経験

---

## 推奨学習順序

### Day 1-2: VLM の世界観（座学中心）

#### VLM とは何か

Vision-Language Model (VLM) は、画像とテキストの両方を理解できる
マルチモーダル AI モデルです。Physical AI にとって、VLM は「目」と「脳」を
つなぐ重要な役割を果たします。

```
従来の画像認識:
  画像 → CNN → "cat" (クラスラベル)

VLM:
  画像 + "この画像に何が写っていますか？" → VLM → "テーブルの上に茶色の猫が座っています。
  猫は窓の方を見ており、日光が差し込んでいます。"
```

#### VLM のアーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│                    VLM アーキテクチャ                      │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │ Vision       │    │ テキスト      │                   │
│  │ Encoder      │    │ トークナイザー │                   │
│  │ (ViT/CLIP)   │    │              │                   │
│  └──────┬───────┘    └──────┬───────┘                   │
│         │                   │                           │
│         ▼                   ▼                           │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │ 画像特徴量    │    │ テキスト      │                   │
│  │ (パッチ      │    │ 埋め込み      │                   │
│  │  トークン)    │    │              │                   │
│  └──────┬───────┘    └──────┬───────┘                   │
│         │                   │                           │
│         └───────┬───────────┘                           │
│                 ▼                                       │
│  ┌──────────────────────────┐                           │
│  │ プロジェクション層          │                           │
│  │ (画像→言語空間への変換)    │                           │
│  └──────────┬───────────────┘                           │
│             ▼                                           │
│  ┌──────────────────────────┐                           │
│  │ 言語モデル (LLM)          │                           │
│  │ Vicuna / LLaMA / Qwen   │                           │
│  └──────────┬───────────────┘                           │
│             ▼                                           │
│  ┌──────────────────────────┐                           │
│  │ テキスト出力               │                           │
│  │ "テーブルの上に猫が..."    │                           │
│  └──────────────────────────┘                           │
└─────────────────────────────────────────────────────────┘
```

#### 主要モデルの比較

| モデル | 開発元 | 特徴 | VRAM 目安 (量子化) | 日本語 |
|---|---|---|---|---|
| LLaVA 1.6 | Microsoft/Wisconsin | オープン、コミュニティ充実 | ~5GB (4-bit, 7B) | 限定的 |
| CogVLM2 | Tsinghua/ZhipuAI | 高性能、大規模 | ~6GB (4-bit) | 対応 |
| Florence-2 | Microsoft | 軽量・効率的、多タスク | ~2GB (FP16) | 限定的 |
| Qwen-VL | Alibaba | 多言語対応、日本語に強い | ~5GB (4-bit, 7B) | 良好 |
| InternVL 2 | Shanghai AI Lab | 高性能、オープン | ~5GB (4-bit) | 対応 |
| Phi-3-Vision | Microsoft | 超軽量、エッジ向け | ~3GB (4-bit) | 限定的 |

> **推奨**: まず **LLaVA 1.6 (7B, 4-bit)** で基本を学び、次に **Qwen-VL** で
> 日本語性能を試しましょう。**Florence-2** は VRAM が厳しい場面で有用です。

#### VLA (Vision-Language-Action) モデル: 次のフロンティア

VLM の発展形として、ロボットの動作まで直接出力する VLA モデルが注目されています。

```
VLM:  画像 + テキスト → テキスト出力
VLA:  画像 + テキスト → ロボットの動作（関節角度、速度指令など）
```

- **RT-2 (Google DeepMind)**: ロボット操作を「言語」として学習
- **Octo (UC Berkeley)**: オープンソースの汎用ロボット操作モデル
- **OpenVLA**: オープンソース VLA、研究用途向け

現時点では VLA モデルの実用的なローカル実行は困難ですが、概念を理解しておくことで、
Physical AI の将来の方向性を掴めます。Week 7-8 では VLM + ルールベースの
コマンド変換で「擬似的な VLA」を構築します。

#### LLM 経験との関連

ローカル LLM デプロイの経験は、VLM の理解に直結します：

| LLM (ローカルデプロイ) | VLM (Month 2) |
|---|---|
| テキストトークン | テキストトークン + 画像パッチトークン |
| テキストエンコーダ | テキストエンコーダ + Vision Encoder |
| GGUF 量子化 | GGUF / GPTQ / AWQ 量子化 |
| llama.cpp 推論 | llama.cpp (一部 VLM 対応) / Transformers |
| プロンプトエンジニアリング | プロンプト + 画像の組み合わせ |

---

### Day 3-5: VLM をローカルで動かす

#### 環境構築

```bash
# conda 環境の作成（推奨）
conda create -n vlm python=3.10 -y
conda activate vlm

# PyTorch のインストール (CUDA 12.x)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# VLM 関連ライブラリ
pip install transformers accelerate bitsandbytes
pip install Pillow opencv-python

# CUDA 確認
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0)}'); print(f'VRAM: {torch.cuda.get_device_properties(0).total_mem / 1024**3:.1f} GB')"
```

> **注意**: WSL2 では Windows 側の NVIDIA ドライバが使われます。
> WSL2 内に別途 CUDA ドライバをインストールする必要はありませんが、
> CUDA Toolkit (nvcc) は別途必要です。

#### CUDA バージョンの確認

```bash
# Windows 側のドライバ確認
nvidia-smi

# PyTorch が認識する CUDA バージョン
python -c "import torch; print(torch.version.cuda)"

# 両者が互換であることを確認
# PyTorch CUDA 12.1 は NVIDIA ドライバ 530+ で動作
```

#### LLaVA の実行（Transformers ライブラリ）

```python
"""
LLaVA 1.6 (7B) を 4-bit 量子化で実行するサンプル
VRAM 使用量: 約 5GB
"""
import torch
from transformers import (
    LlavaNextProcessor,
    LlavaNextForConditionalGeneration,
    BitsAndBytesConfig
)
from PIL import Image
import requests

# --- 4-bit 量子化設定 ---
# 8GB VRAM で 7B モデルを動かすために必須
quantization_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",            # NormalFloat4 (推奨)
    bnb_4bit_compute_dtype=torch.float16,  # 計算は FP16
    bnb_4bit_use_double_quant=True,        # 二重量子化でさらに節約
)

# --- モデルとプロセッサのロード ---
model_id = "llava-hf/llava-v1.6-mistral-7b-hf"

processor = LlavaNextProcessor.from_pretrained(model_id)
model = LlavaNextForConditionalGeneration.from_pretrained(
    model_id,
    quantization_config=quantization_config,
    device_map="auto",      # GPU に自動配置
    torch_dtype=torch.float16,
)

# --- VRAM 使用量の確認 ---
print(f"VRAM 使用量: {torch.cuda.memory_allocated() / 1024**3:.2f} GB")
print(f"VRAM 予約量: {torch.cuda.memory_reserved() / 1024**3:.2f} GB")

# --- 推論 ---
# テスト画像のロード
url = "https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/300px-PNG_transparency_demonstration_1.png"
image = Image.open(requests.get(url, stream=True).raw)

# プロンプトの構築
prompt = "[INST] <image>\nこの画像に何が写っていますか？日本語で詳しく説明してください。 [/INST]"

# 入力の準備
inputs = processor(prompt, image, return_tensors="pt").to(model.device)

# 推論の実行
with torch.no_grad():
    output = model.generate(
        **inputs,
        max_new_tokens=256,
        do_sample=True,
        temperature=0.7,
    )

# 結果のデコード
result = processor.decode(output[0], skip_special_tokens=True)
print(f"\n推論結果:\n{result}")
```

#### 量子化テクニック

8GB VRAM で VLM を動かすために、量子化は必須のテクニックです。

| 手法 | 特徴 | VRAM 削減率 | 品質劣化 | ツール |
|---|---|---|---|---|
| FP16 | 半精度浮動小数点 | ~50% | ほぼなし | PyTorch native |
| GPTQ | 事後量子化 (4/8-bit) | ~75% | 軽微 | auto-gptq |
| AWQ | 活性化考慮量子化 | ~75% | GPTQより少 | autoawq |
| GGUF | llama.cpp 形式 | ~75% | 軽微 | llama.cpp |
| bitsandbytes (NF4) | 4-bit NormalFloat | ~75% | 軽微 | bitsandbytes |

```bash
# GPTQ モデルの使用
pip install auto-gptq optimum

# AWQ モデルの使用
pip install autoawq
```

```python
"""
AWQ 量子化モデルの実行例
"""
from transformers import AutoModelForCausalLM, AutoTokenizer

# AWQ 量子化済みモデルを直接ロード
model = AutoModelForCausalLM.from_pretrained(
    "TheBloke/llava-v1.6-mistral-7b-AWQ",  # AWQ 量子化済み
    device_map="auto",
    torch_dtype=torch.float16,
)
```

```python
"""
GGUF モデルを llama.cpp (Python バインディング) で実行
VLM の llama.cpp 対応はモデルにより異なる
"""
# pip install llama-cpp-python
from llama_cpp import Llama
from llama_cpp.llama_chat_format import Llava15ChatHandler

# GGUF モデルのロード
chat_handler = Llava15ChatHandler(
    clip_model_path="path/to/mmproj-model.gguf"
)
llm = Llama(
    model_path="path/to/llava-model.gguf",
    chat_handler=chat_handler,
    n_gpu_layers=-1,  # 全レイヤーを GPU に
    n_ctx=2048,
)
```

#### 4-bit vs 8-bit のトレードオフ

```
8-bit 量子化:
  ├── VRAM: ~7-8GB (7B モデル) → 8GB VRAM ではギリギリ
  ├── 品質: FP16 とほぼ同等
  └── 速度: FP16 より若干遅い場合あり

4-bit 量子化:
  ├── VRAM: ~4-5GB (7B モデル) → 8GB VRAM で余裕あり
  ├── 品質: わずかに劣化（実用上は問題ない場合が多い）
  └── 速度: 8-bit と同等またはやや速い

推奨: 8GB VRAM では 4-bit 量子化を基本とし、
      残りの VRAM を推論バッファやカメラ処理に使う
```

#### vLLM での高スループット推論

```bash
# vLLM のインストール
pip install vllm
```

```python
"""
vLLM を使った VLM 推論（スループット重視）
注意: vLLM は VRAM を多く使用するため、8GB では制約あり
"""
from vllm import LLM, SamplingParams

# モデルのロード（量子化必須）
llm = LLM(
    model="llava-hf/llava-v1.6-mistral-7b-hf",
    quantization="awq",
    max_model_len=2048,        # コンテキスト長を制限して VRAM 節約
    gpu_memory_utilization=0.8, # VRAM の 80% まで使用
)

params = SamplingParams(temperature=0.7, max_tokens=256)

# 推論（バッチ処理可能）
# vLLM のマルチモーダル対応はバージョンにより異なる
# 最新の vLLM ドキュメントを確認してください
```

#### ベンチマーク: 速度 vs 精度 vs VRAM

自分の環境で以下の項目を計測し、記録しましょう：

```python
"""
ベンチマーク用スクリプト（雛形）
"""
import time
import torch

def benchmark_model(model, processor, image, prompt, n_runs=10):
    """モデルの推論性能を計測"""
    times = []

    # ウォームアップ
    inputs = processor(prompt, image, return_tensors="pt").to(model.device)
    with torch.no_grad():
        _ = model.generate(**inputs, max_new_tokens=50)

    # 計測
    for i in range(n_runs):
        torch.cuda.synchronize()
        start = time.perf_counter()

        inputs = processor(prompt, image, return_tensors="pt").to(model.device)
        with torch.no_grad():
            output = model.generate(**inputs, max_new_tokens=128)

        torch.cuda.synchronize()
        elapsed = time.perf_counter() - start
        times.append(elapsed)

    avg_time = sum(times) / len(times)
    vram_used = torch.cuda.max_memory_allocated() / 1024**3

    print(f"平均推論時間: {avg_time:.3f} 秒")
    print(f"最大 VRAM 使用量: {vram_used:.2f} GB")
    print(f"スループット: {1/avg_time:.1f} 推論/秒")

    return avg_time, vram_used
```

---

### Day 6-8: GPU 最適化

#### TensorRT 最適化パイプライン

TensorRT は NVIDIA GPU に特化した推論最適化エンジンです。
ファームウェアエンジニアとしてのあなたには、「コンパイラが最適なマシンコードを
生成する」という感覚で理解できるでしょう。

```
モデル最適化パイプライン:
  PyTorch モデル → ONNX エクスポート → TensorRT エンジン → 高速推論

各段階のイメージ:
  ├── PyTorch: C++ ソースコード（汎用的だが最適化されていない）
  ├── ONNX: 中間表現 (LLVM IR のようなもの)
  └── TensorRT: ターゲット GPU 向けにコンパイルされたバイナリ
```

```bash
# TensorRT のインストール（WSL2）
pip install tensorrt
pip install onnx onnxruntime-gpu

# 確認
python -c "import tensorrt; print(tensorrt.__version__)"
```

##### ONNX エクスポート

```python
"""
Vision Encoder 部分の ONNX エクスポート例
注意: VLM 全体の ONNX エクスポートは複雑なため、
      まずは Vision Encoder 部分から始める
"""
import torch
import onnx

# Vision Encoder の取り出し（モデルにより異なる）
vision_encoder = model.vision_tower

# ダミー入力
dummy_input = torch.randn(1, 3, 336, 336).cuda().half()

# ONNX エクスポート
torch.onnx.export(
    vision_encoder,
    dummy_input,
    "vision_encoder.onnx",
    input_names=["pixel_values"],
    output_names=["image_features"],
    dynamic_axes={
        "pixel_values": {0: "batch_size"},
        "image_features": {0: "batch_size"},
    },
    opset_version=17,
)

print("ONNX エクスポート完了")
```

##### TensorRT エンジンビルド

```python
"""
TensorRT エンジンのビルドと推論
"""
import tensorrt as trt

def build_engine(onnx_path, engine_path, fp16=True):
    """ONNX モデルから TensorRT エンジンをビルド"""
    logger = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(
        1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
    )
    parser = trt.OnnxParser(network, logger)

    # ONNX モデルの読み込み
    with open(onnx_path, "rb") as f:
        if not parser.parse(f.read()):
            for error in range(parser.num_errors):
                print(parser.get_error(error))
            return None

    # ビルド設定
    config = builder.create_builder_config()
    config.set_memory_pool_limit(
        trt.MemoryPoolType.WORKSPACE, 2 << 30  # 2GB ワークスペース
    )

    if fp16:
        config.set_flag(trt.BuilderFlag.FP16)

    # エンジンのビルド（数分かかる場合あり）
    print("TensorRT エンジンをビルド中...")
    serialized_engine = builder.build_serialized_network(network, config)

    # エンジンの保存
    with open(engine_path, "wb") as f:
        f.write(serialized_engine)

    print(f"エンジン保存完了: {engine_path}")
    return serialized_engine
```

#### ONNX Runtime with CUDA

TensorRT の代替として、ONNX Runtime も有効です。
セットアップが簡単で、十分な高速化が得られます。

```python
"""
ONNX Runtime (CUDA) での推論
"""
import onnxruntime as ort
import numpy as np

# セッションの作成
providers = [
    ("CUDAExecutionProvider", {
        "device_id": 0,
        "arena_extend_strategy": "kSameAsRequested",
        "gpu_mem_limit": 4 * 1024 * 1024 * 1024,  # 4GB 制限
    }),
    "CPUExecutionProvider",  # フォールバック
]

session = ort.InferenceSession("vision_encoder.onnx", providers=providers)

# 推論
input_data = np.random.randn(1, 3, 336, 336).astype(np.float16)
result = session.run(None, {"pixel_values": input_data})

print(f"出力形状: {result[0].shape}")
```

#### メモリプロファイリング

```python
"""
GPU メモリのプロファイリング
ファームウェア開発での メモリデバッグと同様の感覚で
"""
import torch

def print_gpu_memory():
    """GPU メモリ使用状況を表示"""
    allocated = torch.cuda.memory_allocated() / 1024**3
    reserved = torch.cuda.memory_reserved() / 1024**3
    max_allocated = torch.cuda.max_memory_allocated() / 1024**3

    print(f"割り当て済み:   {allocated:.2f} GB")
    print(f"予約済み:       {reserved:.2f} GB")
    print(f"最大割り当て:   {max_allocated:.2f} GB")
    print(f"空き (予約内):  {reserved - allocated:.2f} GB")

# 使用例
print("--- モデルロード前 ---")
print_gpu_memory()

# モデルロード
model = load_model()

print("\n--- モデルロード後 ---")
print_gpu_memory()

# 推論
result = run_inference(model, image)

print("\n--- 推論後 ---")
print_gpu_memory()

# メモリ解放
torch.cuda.empty_cache()
print("\n--- キャッシュクリア後 ---")
print_gpu_memory()
```

#### 8GB VRAM での最適化比較

| 最適化手法 | 推論速度 | VRAM 使用量 | 導入難易度 | 推奨度 |
|---|---|---|---|---|
| bitsandbytes 4-bit | 中 | ~5GB | 低 | 最初にこれ |
| AWQ 量子化 | 中～高 | ~5GB | 低 | 品質重視 |
| GPTQ 量子化 | 中～高 | ~5GB | 低 | 互換性重視 |
| GGUF + llama.cpp | 高 | ~4GB | 中 | CPU オフロード可 |
| ONNX Runtime | 高 | ~4GB | 中 | 安定性重視 |
| TensorRT | 最高 | ~4GB | 高 | 最終最適化 |

> **推奨アプローチ**: bitsandbytes 4-bit → AWQ → TensorRT の順に試す

---

### Day 9-10: カメラ → VLM パイプライン

#### OpenCV カメラキャプチャ

```python
"""
Web カメラからの画像キャプチャ
WSL2 での USB カメラ使用には usbipd-win が必要
"""
import cv2

def capture_from_camera(device_id=0):
    """カメラから 1 フレームをキャプチャ"""
    cap = cv2.VideoCapture(device_id)

    if not cap.isOpened():
        print("カメラを開けません。仮想カメラを使用します。")
        return None

    ret, frame = cap.read()
    cap.release()

    if ret:
        return frame
    return None

def capture_from_file(image_path):
    """
    カメラが使えない場合のフォールバック
    WSL2 でカメラアクセスが困難な場合に使用
    """
    frame = cv2.imread(image_path)
    return frame

# WSL2 で USB カメラを使うためのセットアップ
# (Windows 側で実行)
# > usbipd list
# > usbipd bind --busid <busid>
# > usbipd attach --wsl --busid <busid>
```

#### 画像前処理

```python
"""
VLM 入力用の画像前処理
"""
import cv2
import numpy as np
from PIL import Image

def preprocess_frame(frame, target_size=(336, 336)):
    """OpenCV フレームを VLM 入力用に前処理"""
    # BGR → RGB 変換 (OpenCV は BGR, PIL/Transformers は RGB)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # PIL Image に変換
    pil_image = Image.fromarray(rgb_frame)

    # リサイズ（アスペクト比維持はプロセッサが処理）
    # 必要に応じてここでリサイズ
    # pil_image = pil_image.resize(target_size)

    return pil_image

def add_overlay(frame, text, fps=0):
    """デバッグ用のオーバーレイ表示"""
    # FPS 表示
    cv2.putText(frame, f"FPS: {fps:.1f}", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    # 推論結果表示（複数行対応）
    y_offset = 60
    for i, line in enumerate(text.split('\n')[:5]):
        cv2.putText(frame, line, (10, y_offset + i * 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)

    return frame
```

#### フルパイプラインの構築

```python
"""
カメラ → 前処理 → VLM 推論 → 出力の全パイプライン
"""
import cv2
import time
import torch
from threading import Thread, Event
from queue import Queue

class VLMPipeline:
    """カメラ→VLM パイプライン"""

    def __init__(self, model, processor, device_id=0):
        self.model = model
        self.processor = processor
        self.device_id = device_id
        self.result_queue = Queue(maxsize=1)
        self.frame_queue = Queue(maxsize=1)
        self.stop_event = Event()
        self.latest_result = "推論待機中..."

    def camera_thread(self):
        """カメラキャプチャスレッド"""
        cap = cv2.VideoCapture(self.device_id)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

        while not self.stop_event.is_set():
            ret, frame = cap.read()
            if ret:
                # 最新フレームのみ保持（古いフレームは捨てる）
                if not self.frame_queue.full():
                    self.frame_queue.put(frame)
                else:
                    try:
                        self.frame_queue.get_nowait()
                        self.frame_queue.put(frame)
                    except:
                        pass

        cap.release()

    def inference_thread(self):
        """VLM 推論スレッド（非同期）"""
        prompt = "[INST] <image>\nこの画像に何が写っていますか？簡潔に日本語で説明してください。 [/INST]"

        while not self.stop_event.is_set():
            try:
                frame = self.frame_queue.get(timeout=1.0)
            except:
                continue

            # 前処理
            pil_image = preprocess_frame(frame)

            # 推論
            start = time.perf_counter()
            inputs = self.processor(prompt, pil_image, return_tensors="pt").to(
                self.model.device
            )
            with torch.no_grad():
                output = self.model.generate(
                    **inputs, max_new_tokens=100
                )
            result = self.processor.decode(output[0], skip_special_tokens=True)
            elapsed = time.perf_counter() - start

            self.latest_result = f"({elapsed:.1f}s) {result}"

    def run(self):
        """パイプラインの実行"""
        # スレッドの起動
        cam_t = Thread(target=self.camera_thread, daemon=True)
        inf_t = Thread(target=self.inference_thread, daemon=True)
        cam_t.start()
        inf_t.start()

        print("パイプライン実行中... 'q' で終了")

        try:
            while True:
                if not self.frame_queue.empty():
                    # 表示用フレームの取得
                    frame = self.frame_queue.queue[-1] if self.frame_queue.queue else None
                    if frame is not None:
                        display = add_overlay(frame.copy(), self.latest_result)
                        cv2.imshow("VLM Pipeline", display)

                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
        finally:
            self.stop_event.set()
            cv2.destroyAllWindows()

# 使用例
# pipeline = VLMPipeline(model, processor, device_id=0)
# pipeline.run()
```

---

### Day 11-12: 音声認識 (Whisper)

#### Whisper モデルの概要

| モデル | パラメータ | VRAM 目安 | 相対速度 | 日本語精度 |
|---|---|---|---|---|
| tiny | 39M | ~1GB | 32x | 低 |
| base | 74M | ~1GB | 16x | やや低 |
| small | 244M | ~2GB | 6x | 中 |
| medium | 769M | ~5GB | 2x | 高 |
| large-v3 | 1.55B | ~10GB | 1x | 最高 |

> **推奨**: VLM と同時に使う場合、VRAM に余裕を残すために **small** を推奨。
> VLM を停止できる場合は **medium** も使用可能。

#### Whisper のローカル実行

```python
"""
Whisper によるローカル音声認識
"""
import torch
from transformers import WhisperProcessor, WhisperForConditionalGeneration

# モデルのロード (small モデル)
processor = WhisperProcessor.from_pretrained("openai/whisper-small")
model = WhisperForConditionalGeneration.from_pretrained(
    "openai/whisper-small"
).to("cuda")

# VRAM 使用量の確認
print(f"Whisper VRAM: {torch.cuda.memory_allocated() / 1024**3:.2f} GB")
```

#### faster-whisper による最適化

```bash
pip install faster-whisper
```

```python
"""
faster-whisper: CTranslate2 ベースの高速 Whisper 実装
Whisper の 4 倍高速、メモリ使用量も少ない
"""
from faster_whisper import WhisperModel

# モデルのロード
# compute_type: "float16", "int8_float16", "int8"
model = WhisperModel(
    "small",                    # モデルサイズ
    device="cuda",
    compute_type="float16",     # RTX 5070 では float16 推奨
)

# 音声ファイルからの認識
segments, info = model.transcribe(
    "audio.wav",
    language="ja",              # 日本語を指定
    beam_size=5,
)

print(f"検出言語: {info.language} (確率: {info.language_probability:.2f})")
for segment in segments:
    print(f"[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}")
```

#### リアルタイム音声認識パイプライン

```python
"""
マイクからのリアルタイム音声認識
WSL2 ではオーディオデバイスのアクセスに注意が必要
"""
import pyaudio
import numpy as np
import wave
from faster_whisper import WhisperModel

class RealtimeSpeechRecognizer:
    """リアルタイム音声認識"""

    def __init__(self, model_size="small", language="ja"):
        self.model = WhisperModel(
            model_size, device="cuda", compute_type="float16"
        )
        self.language = language

        # オーディオ設定
        self.sample_rate = 16000
        self.chunk_size = 1024
        self.record_seconds = 5  # 5 秒ごとに認識

    def record_audio(self, duration=5):
        """マイクから音声を録音"""
        p = pyaudio.PyAudio()
        stream = p.open(
            format=pyaudio.paFloat32,
            channels=1,
            rate=self.sample_rate,
            input=True,
            frames_per_buffer=self.chunk_size,
        )

        print(f"録音中... ({duration}秒)")
        frames = []
        for _ in range(0, int(self.sample_rate / self.chunk_size * duration)):
            data = stream.read(self.chunk_size)
            frames.append(np.frombuffer(data, dtype=np.float32))

        stream.stop_stream()
        stream.close()
        p.terminate()

        return np.concatenate(frames)

    def transcribe(self, audio_data):
        """音声データをテキストに変換"""
        # 一時ファイルに保存（faster-whisper はファイル入力を期待）
        temp_path = "/tmp/temp_audio.wav"
        with wave.open(temp_path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(4)  # float32
            wf.setframerate(self.sample_rate)
            wf.writeframes(audio_data.tobytes())

        segments, _ = self.model.transcribe(
            temp_path, language=self.language
        )
        text = " ".join([s.text for s in segments])
        return text.strip()

    def run_continuous(self):
        """連続音声認識"""
        print("音声認識開始... Ctrl+C で終了")
        try:
            while True:
                audio = self.record_audio(duration=self.record_seconds)
                text = self.transcribe(audio)
                if text:
                    print(f"認識結果: {text}")
        except KeyboardInterrupt:
            print("\n音声認識終了")

# 使用例
# recognizer = RealtimeSpeechRecognizer(model_size="small", language="ja")
# recognizer.run_continuous()
```

#### 日本語サポートに関する注意

```python
# Whisper の日本語認識品質を上げるコツ

# 1. 言語を明示的に指定する
segments, info = model.transcribe("audio.wav", language="ja")

# 2. initial_prompt で文脈を与える
segments, info = model.transcribe(
    "audio.wav",
    language="ja",
    initial_prompt="ロボットに指示を出します。前に進め、左に曲がれ。",
)

# 3. VAD (Voice Activity Detection) を有効にする
segments, info = model.transcribe(
    "audio.wav",
    language="ja",
    vad_filter=True,           # 無音区間をスキップ
    vad_parameters=dict(
        min_silence_duration_ms=500,
    ),
)
```

---

### Day 13-14: 統合テスト

#### Camera + VLM + Whisper の統合

```python
"""
マルチモーダルデモ: カメラ + VLM + 音声認識
1. カメラで物体を撮影
2. 音声で質問
3. VLM が画像を見て回答
"""

class MultimodalDemo:
    """マルチモーダル統合デモ"""

    def __init__(self):
        # VLM のロード
        self.vlm_model, self.vlm_processor = self._load_vlm()

        # Whisper のロード
        self.whisper = WhisperModel("small", device="cuda", compute_type="float16")

        # VRAM 確認
        print(f"合計 VRAM 使用量: {torch.cuda.memory_allocated() / 1024**3:.2f} GB")

    def _load_vlm(self):
        """VLM の省メモリロード"""
        # 4-bit 量子化で VRAM を節約し、Whisper と共存させる
        quantization_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=torch.float16,
            bnb_4bit_use_double_quant=True,
        )
        processor = LlavaNextProcessor.from_pretrained(model_id)
        model = LlavaNextForConditionalGeneration.from_pretrained(
            model_id,
            quantization_config=quantization_config,
            device_map="auto",
        )
        return model, processor

    def capture_image(self):
        """カメラから画像をキャプチャ"""
        cap = cv2.VideoCapture(0)
        ret, frame = cap.read()
        cap.release()
        if ret:
            return Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        return None

    def listen(self, duration=5):
        """音声を録音して認識"""
        recognizer = RealtimeSpeechRecognizer("small", "ja")
        audio = recognizer.record_audio(duration)
        text = recognizer.transcribe(audio)
        return text

    def ask_vlm(self, image, question):
        """VLM に画像について質問"""
        prompt = f"[INST] <image>\n{question} [/INST]"
        inputs = self.vlm_processor(prompt, image, return_tensors="pt").to(
            self.vlm_model.device
        )
        with torch.no_grad():
            output = self.vlm_model.generate(**inputs, max_new_tokens=200)
        return self.vlm_processor.decode(output[0], skip_special_tokens=True)

    def run(self):
        """デモの実行"""
        print("=== マルチモーダルデモ ===")
        print("カメラに物体を見せて、音声で質問してください。")
        print("'終了' と言うと終了します。\n")

        while True:
            # 画像キャプチャ
            print("画像をキャプチャしています...")
            image = self.capture_image()
            if image is None:
                print("カメラエラー。ファイルから読み込みます。")
                image = Image.open("test_image.jpg")

            # 音声入力
            print("質問を話してください (5秒間)...")
            question = self.listen(duration=5)
            print(f"認識結果: {question}")

            if "終了" in question:
                print("デモを終了します。")
                break

            # VLM に質問
            print("VLM が回答を生成中...")
            answer = self.ask_vlm(image, question)
            print(f"\n回答: {answer}\n")

# 実行
# demo = MultimodalDemo()
# demo.run()
```

#### パフォーマンスプロファイリング

```python
"""
パフォーマンス計測結果を記録するテンプレート
"""
performance_log = {
    "environment": {
        "gpu": "RTX 5070 (8GB)",
        "cuda": "12.x",
        "pytorch": torch.__version__,
    },
    "vlm": {
        "model": "llava-v1.6-mistral-7b",
        "quantization": "4-bit (NF4)",
        "vram_usage_gb": 0.0,        # 計測値を記入
        "inference_time_sec": 0.0,    # 計測値を記入
        "tokens_per_sec": 0.0,        # 計測値を記入
    },
    "whisper": {
        "model": "small",
        "compute_type": "float16",
        "vram_usage_gb": 0.0,         # 計測値を記入
        "rtf": 0.0,                   # Real-Time Factor
    },
    "combined": {
        "total_vram_gb": 0.0,         # 計測値を記入
        "end_to_end_latency_sec": 0.0, # 計測値を記入
    },
}
```

---

## 練習課題

各課題は独立して実施でき、段階的にスキルを積み上げる構成です。

| 課題 | 内容 | 目安時間 | 難易度 |
|---|---|---|---|
| [exercise01](exercises/exercise01_vlm_inference.md) | VLM で画像を認識する | 2-3h | 基礎 |
| [exercise02](exercises/exercise02_quantization.md) | 4-bit vs 8-bit 量子化の比較 | 2-3h | 基礎 |
| [exercise03](exercises/exercise03_tensorrt_optimization.md) | TensorRT でモデルを最適化 | 3-4h | 中級 |
| [exercise04](exercises/exercise04_camera_pipeline.md) | カメラ→VLM パイプライン構築 | 3-4h | 中級 |
| [exercise05](exercises/exercise05_whisper_speech.md) | リアルタイム音声認識 | 2-3h | 基礎 |
| [exercise06](exercises/exercise06_multimodal_demo.md) | 視覚＋音声の統合デモ | 4-5h | 応用 |

### 課題の進め方

1. まず exercise01 と exercise02 を完了し、VLM の基本操作に慣れる
2. exercise03 で最適化テクニックを学ぶ（つまずいたら飛ばして可）
3. exercise04 でカメラ連携を構築
4. exercise05 で音声認識を追加
5. exercise06 で全てを統合

---

## 到達確認チェックリスト

以下の項目を全てチェックできれば、Week 5-6 の学習は完了です。

### VLM の理解

- [ ] VLM のアーキテクチャ（Vision Encoder + Projection + LLM）を図で説明できる
- [ ] 主要な VLM モデル（LLaVA, Qwen-VL, Florence-2）の特徴を比較できる
- [ ] VLA (Vision-Language-Action) モデルの概念を説明できる
- [ ] VLM と従来の画像認識 (CNN分類) の違いを説明できる

### ローカル実行

- [ ] LLaVA (7B, 4-bit) を WSL2 + RTX 5070 で実行できる
- [ ] VRAM 使用量を監視し、OOM エラーに対処できる
- [ ] nvidia-smi で GPU 状態を確認できる
- [ ] 量子化（4-bit/8-bit）の違いを実測値で比較できる

### 最適化

- [ ] GPTQ, AWQ, GGUF, bitsandbytes の違いを説明できる
- [ ] ONNX エクスポートの基本手順を理解している
- [ ] TensorRT の概念（ONNX → エンジンビルド → 推論）を説明できる
- [ ] 自分の環境でのベンチマーク結果を記録している

### パイプライン

- [ ] OpenCV でカメラ画像をキャプチャできる（または仮想カメラを使用）
- [ ] カメラ画像を VLM に入力し、テキスト出力を得られる
- [ ] 非同期処理（スレッド）で推論のブロッキングを回避できる

### 音声認識

- [ ] Whisper (small) をローカルで実行できる
- [ ] faster-whisper を使った高速推論ができる
- [ ] 日本語音声認識の結果を取得できる
- [ ] リアルタイム音声認識の基本パイプラインが動作する

### 統合

- [ ] VLM + Whisper を同時にロードした際の VRAM 使用量を把握している
- [ ] 「画像を見せて音声で質問→回答」の基本デモが動作する

---

## つまずきやすいポイントと対処法

### 1. VRAM OOM エラー (8GB 制限)

**症状**: `torch.cuda.OutOfMemoryError: CUDA out of memory`

**対処法**:
```python
# 1. より積極的な量子化を使用
quantization_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_use_double_quant=True,  # 二重量子化
)

# 2. 不要なモデルを解放
del model
torch.cuda.empty_cache()

# 3. max_new_tokens を減らす
output = model.generate(**inputs, max_new_tokens=50)  # 256 → 50

# 4. 入力画像サイズを小さくする
image = image.resize((224, 224))  # 336 → 224

# 5. 環境変数で断片化を軽減
import os
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
```

### 2. CUDA バージョンの不一致

**症状**: `RuntimeError: CUDA error: no kernel image is available for execution`

**対処法**:
```bash
# PyTorch が認識する CUDA バージョンを確認
python -c "import torch; print(torch.version.cuda)"

# システムの CUDA バージョンを確認
nvcc --version

# 不一致の場合、PyTorch を再インストール
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

### 3. 量子化の互換性問題

**症状**: モデルロード時のエラー、互換性の問題

**対処法**:
```bash
# bitsandbytes の最新版を使用
pip install bitsandbytes --upgrade

# WSL2 固有の問題がある場合
# libcuda.so のシンボリックリンクを確認
ls -la /usr/lib/wsl/lib/libcuda.so*

# auto-gptq のバージョン互換性に注意
pip install auto-gptq==0.7.1  # 安定バージョンを指定
```

### 4. TensorRT ビルド失敗

**症状**: TensorRT エンジンのビルドが失敗する

**対処法**:
- ONNX opset バージョンを変更して再エクスポート
- サポートされていない演算子がある場合、手動で置き換え
- TensorRT バージョンと CUDA バージョンの互換性を確認
- まずは ONNX Runtime (CUDA) で試し、問題なければ TensorRT に進む

### 5. WSL2 カメラアクセス

**症状**: `cv2.VideoCapture(0)` でカメラが開けない

**対処法**:
```bash
# 方法1: usbipd-win で USB カメラをパススルー
# Windows 側 (PowerShell, 管理者):
# > winget install usbipd
# > usbipd list
# > usbipd bind --busid <BUSID>
# > usbipd attach --wsl --busid <BUSID>

# WSL2 側:
sudo apt install linux-tools-virtual hwdata
ls /dev/video*  # デバイスが見えるか確認

# 方法2: 仮想カメラ（画像ファイルを使用）
# カメラが使えない場合のフォールバック
# テスト用画像をダウンロードして使用
```

### 6. モデルダウンロードの問題

**症状**: HuggingFace からのダウンロードが遅い・失敗する

**対処法**:
```bash
# 高速ダウンロードを有効化
pip install hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1

# キャッシュディレクトリの変更（SSD に配置）
export HF_HOME=/path/to/fast/storage/.cache/huggingface

# 部分的なダウンロードのレジューム
# huggingface-cli を使用
huggingface-cli download llava-hf/llava-v1.6-mistral-7b-hf --resume-download
```

### 7. VLM の日本語出力の質

**症状**: VLM が日本語で回答しない、または質が低い

**対処法**:
```python
# 1. プロンプトで日本語を明示的に指示
prompt = "[INST] <image>\n日本語で回答してください。この画像に何が写っていますか？ [/INST]"

# 2. 日本語に強いモデルを使用
# Qwen-VL は日本語サポートが比較的良好
model_id = "Qwen/Qwen-VL-Chat"

# 3. system prompt で言語を固定（モデルが対応している場合）
```

---

## 参考リンク

### VLM 関連

- [LLaVA プロジェクトページ](https://llava-vl.github.io/)
- [Hugging Face: LLaVA モデル](https://huggingface.co/llava-hf)
- [Qwen-VL (GitHub)](https://github.com/QwenLM/Qwen-VL)
- [Florence-2 (Hugging Face)](https://huggingface.co/microsoft/Florence-2-large)
- [InternVL (GitHub)](https://github.com/OpenGVLab/InternVL)

### 量子化・最適化

- [bitsandbytes ドキュメント](https://huggingface.co/docs/bitsandbytes)
- [AutoGPTQ (GitHub)](https://github.com/AutoGPTQ/AutoGPTQ)
- [AutoAWQ (GitHub)](https://github.com/casper-hansen/AutoAWQ)
- [llama.cpp (GitHub)](https://github.com/ggerganov/llama.cpp)
- [vLLM ドキュメント](https://docs.vllm.ai/)
- [TensorRT ドキュメント](https://docs.nvidia.com/deeplearning/tensorrt/)
- [ONNX Runtime](https://onnxruntime.ai/)

### 音声認識

- [OpenAI Whisper (GitHub)](https://github.com/openai/whisper)
- [faster-whisper (GitHub)](https://github.com/SYSTRAN/faster-whisper)
- [Whisper モデルカード (Hugging Face)](https://huggingface.co/openai/whisper-large-v3)

### VLA (Vision-Language-Action)

- [RT-2 論文](https://arxiv.org/abs/2307.15818)
- [Octo (GitHub)](https://github.com/octo-models/octo)
- [OpenVLA (GitHub)](https://github.com/openvla/openvla)

### 開発環境

- [WSL2 で GPU を使う (NVIDIA)](https://docs.nvidia.com/cuda/wsl-user-guide/)
- [usbipd-win (GitHub)](https://github.com/dorssel/usbipd-win)
- [PyTorch インストールガイド](https://pytorch.org/get-started/locally/)

### 学習リソース

- [3Blue1Brown: Neural Networks (YouTube)](https://www.youtube.com/playlist?list=PLZHQObOWTQDNU6R1_67000Dx_ZCJB-3pi)
- [Andrej Karpathy: Neural Networks: Zero to Hero](https://karpathy.ai/zero-to-hero.html)
- [Hugging Face: Transformers チュートリアル](https://huggingface.co/docs/transformers/index)

---

> **次のステップ**: Week 5-6 の内容を完了したら、
> [Week 7-8: ROS 2 + AI 統合パイプライン](../week7-8-ros2-ai-pipeline/README.md) に進みましょう。
