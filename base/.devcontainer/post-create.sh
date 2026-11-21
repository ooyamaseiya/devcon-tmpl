#!/usr/bin/env bash
set -euo pipefail

# Dockerfile 側で全てインストール済みのため、ここでは
# コンテナ起動時にマウントされたルート証明書をシステムに反映させる処理のみ実行

if command -v sudo >/dev/null 2>&1; then
    sudo update-ca-certificates
else
    update-ca-certificates
fi

echo "[post-create] CA certificates updated successfully."
