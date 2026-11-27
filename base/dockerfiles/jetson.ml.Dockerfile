FROM ubuntu:noble-20261110.1

ENV DEBIAN_FRONTEND=noninteractive

# 基本ツール・Python・動画処理用ライブラリをインストール
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    git wget ffmpeg libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# コンテナ内に仮想環境を作成してPATHを通す
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 1. PyTorch 公式の Arm64 + CUDA 13.2 対応 wheel を先に入れる
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision \
    --index-url https://download.pytorch.org/whl/cu132

# 2. SAM 2 をインストール（CUDA拡張ビルド回避・既存torchを維持）
WORKDIR /opt
RUN git clone https://github.com/facebookresearch/sam2.git
WORKDIR /opt/sam2
RUN pip install --no-cache-dir hydra-core iopath tqdm pillow matplotlib && \
    SAM2_BUILD_CUDA=0 pip install --no-cache-dir --no-build-isolation --no-deps -e .

# 軽量モデル（sam2.1_hiera_tiny）の重みを事前ダウンロード
RUN mkdir -p /opt/sam2/checkpoints && \
    wget -q https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_tiny.pt \
    -P /opt/sam2/checkpoints

# 3. Ultralytics YOLO と ONNX 変換用パッケージを追加（torchを上書きしないよう --no-deps）
RUN pip install --no-cache-dir --no-deps ultralytics && \
    pip install --no-cache-dir pyyaml scipy psutil py-cpuinfo opencv-python-headless onnx onnxslim

WORKDIR /workspace
