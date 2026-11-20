#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".devcontainer/.env"
ENV_EXAMPLE_FILE=".devcontainer/.env.example"

# 名前解決したい「環境変数名:ホスト名」のペアを定義（増えたらここに追加）
TARGET_HOSTS=(
  "DEV_INFER_IP:dev-infer.local"
  # "DEV_DB_IP:dev-db.local"
  # "DEV_STORAGE_IP:dev-storage.local"
)

# 1. .env が未作成で .env.example がある場合は初期コピー
if [[ ! -f "$ENV_FILE" && -f "$ENV_EXAMPLE_FILE" ]]; then
  cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
fi
touch "$ENV_FILE"

# 2. IPv4 名前解決ヘルパー（Linux / macOS 対応）
resolve_ipv4() {
  local host="$1"
  if command -v getent >/dev/null 2>&1; then
    getent ahostsv4 "$host" 2>/dev/null | awk '{print $1; exit}'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import socket; print(socket.gethostbyname('$host'))" 2>/dev/null || true
  fi
}

# 3. .env の特定キーだけを安全に更新・追記する関数（他の行は維持）
upsert_env() {
  local key="$1"
  local value="$2"
  local file="$3"

  awk -v k="$key" -v v="$value" '
    BEGIN { found = 0 }
    $0 ~ "^" k "=" { print k "=" v; found = 1; next }
    { print }
    END { if (!found) print k "=" v }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

# 4. 定義された全ホストを名前解決して .env に反映
for entry in "${TARGET_HOSTS[@]}"; do
  var_name="${entry%%:*}"
  hostname="${entry#*:}"

  ip=$(resolve_ipv4 "$hostname")
  resolved_ip="${ip:-127.0.0.1}"

  upsert_env "$var_name" "$resolved_ip" "$ENV_FILE"
  echo "[init] ${var_name}=${resolved_ip} (${hostname})"
done

# 5. その他の動的変数も同様に共存可能
upsert_env "PROJECT_NAME" "${PROJECT_NAME:-$(basename "$PWD")}" "$ENV_FILE"

