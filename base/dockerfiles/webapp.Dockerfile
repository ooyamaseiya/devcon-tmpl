# 不整合を防ぐため、Node.js向けのベースイメージはハードコードに戻す
FROM mcr.microsoft.com/devcontainers/typescript-node:26-trixie

# FROM以後に再度ARGを宣言
ARG PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cpu"
ARG PLAYWRIGHT_VERSION=1.52.0

# ユーザーに依存しない共有パスに配置する
ENV VIRTUAL_ENV=/opt/venv
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# 1. システムパッケージ（Python、音声処理ライブラリ）と uv のインストール
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        libsndfile1 \
        ffmpeg \
    && pip install --break-system-packages --no-cache-dir uv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. 共通CLIツール（repomix）
RUN npm install -g repomix

# 3. Playwright（ブラウザを共有パス /opt/ms-playwright へ配置）
RUN npx -y playwright@${PLAYWRIGHT_VERSION} install --with-deps chromium \
    && chmod -R a+rwX ${PLAYWRIGHT_BROWSERS_PATH}

# 4. Python 仮想環境の作成と機械学習・音声処理パッケージのインストール
RUN python3 -m venv ${VIRTUAL_ENV} \
    && uv pip install --upgrade pip \
    && uv pip install --no-cache \
        torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL} \
    && uv pip install --no-cache \
        gymnasium \
        stable-baselines3 \
        librosa \
        soundfile \
        onnx \
        onnxruntime \
        scikit-learn \
        pytest \
    && chmod -R a+rwX ${VIRTUAL_ENV}

# 5. opencode のインストール（全ユーザーから使えるよう /usr/local/bin へ配置）
RUN curl -fsSL https://opencode.ai/v2/install | bash \
    && mv /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && rm -rf /root/.opencode
