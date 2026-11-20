FROM mcr.microsoft.com/devcontainers/cpp:trixie

# どのユーザー（root / vscode等）からでも同じPlatformIOキャッシュを参照できるよう固定
ENV PLATFORMIO_CORE_DIR=/opt/platformio

# 1. Python + USBシリアル関連パッケージ + Node.js を一括導入
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
       python3 python3-pip python3-venv udev usbutils curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. PlatformIO CLI と共通Nodeツール（opencode-ai / repomix）の導入
RUN pip install --break-system-packages --no-cache-dir platformio \
    && npm install -g opencode-ai repomix

# 3. 必須ライブラリをグローバル領域に焼き込む（M5GFXも自動で入ります）
RUN pio pkg install -g --library "m5stack/M5Unified"

# 4. ダミープロジェクトでESP32 / ESP32-S3のツールチェーン＆フレームワークを焼き込む
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

