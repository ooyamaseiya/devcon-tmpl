FROM mcr.microsoft.com/devcontainers/cpp:trixie

# ユーザー非依存の共有パス＆root実行時のGUI/SDL2用環境変数を設定
ENV PLATFORMIO_CORE_DIR=/opt/platformio
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV DISPLAY=:99
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

# 1. システムパッケージ（Python / USB / GUI・VNC関連 / Node.js）を一括導入
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
       python3 \
       python3-pip \
       python3-venv \
       udev \
       usbutils \
       curl \
       ca-certificates \
       libsdl2-dev \
       xvfb \
       imagemagick \
       x11vnc \
       novnc \
       websockify \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${XDG_RUNTIME_DIR} && chmod 700 ${XDG_RUNTIME_DIR}

# 2. 共有Python仮想環境（/opt/venv）に PlatformIO CLI と pyserial を導入
RUN python3 -m venv ${VIRTUAL_ENV} \
    && pip install --no-cache-dir --upgrade pip uv \
    && uv pip install --no-cache \
       platformio \
       pyserial \
    && chmod -R a+rwX ${VIRTUAL_ENV}

# 3. 共通CLIツール（repomix / opencode）をグローバルパスへ導入
RUN npm install -g repomix \
    && curl -fsSL https://opencode.ai/v2/install | bash \
    && mv /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && rm -rf /root/.opencode

# 4. 必須ライブラリをグローバル領域に焼き込む（M5GFXも自動で入ります）
RUN pio pkg install -g --library "m5stack/M5Unified"

# 5. ダミープロジェクトでESP32 / ESP32-S3のツールチェーン＆フレームワークを焼き込む
RUN mkdir -p /tmp/pio-warmup/src \
    && printf '%s\n' \
      '[env:m5stack-core2]' \
      'platform = espressif32' \
      'board = m5stack-core2' \
      'framework = arduino' \
      '' \
      '[env:m5stack-cores3]' \
      'platform = espressif32' \
      'board = m5stack-cores3' \
      'framework = arduino' \
      > /tmp/pio-warmup/platformio.ini \
    && printf '%s\n' \
      '#include <M5Unified.h>' \
      'void setup() { M5.begin(); }' \
      'void loop() {}' \
      > /tmp/pio-warmup/src/main.cpp \
    && pio run -d /tmp/pio-warmup \
    && rm -rf /tmp/pio-warmup \
    && chmod -R a+rwX ${PLATFORMIO_CORE_DIR}
