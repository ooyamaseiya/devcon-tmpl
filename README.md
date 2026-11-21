# devcon-tmpl

## M5Stack シミュレーターの使い分け（m5.Dockerfile 利用時）

プロジェクトの `platformio.ini` には用途別に3つの環境を定義して使います。

| 環境名         | 用途                   | 特徴                                          |
| :------------- | :--------------------- | :-------------------------------------------- |
| `env:sim`      | 自動テスト・AI確認用   | `-DAUTO_EXIT_MS=3000` により3秒で自動終了する |
| `env:sim-live` | 人間の目視デバッグ用   | 自動終了せず、noVNC 越しに画面操作できる      |
| `env:device`   | M5Stack 実機書き込み用 | USB 経由で実機に転送する                      |

### 1. ブラウザ（noVNC）で `sim-live` を確認する手順

コンテナ内で仮想ディスプレイと noVNC を起動し、ホストのブラウザで `http://localhost:6080/vnc.html` にアクセスします。

```bash
# バックグラウンドで仮想画面・VNC・noVNCを起動
Xvfb :99 -screen 0 640x480x24 &
x11vnc -display :99 -nopw -forever -shared &
websockify --web=/usr/share/novnc/ 6080 localhost:5900 &

# シミュレーターをビルドして実行
pio run -e sim-live
.pio/build/sim-live/program
```

## GitHub CLI (gh) を使った PAT の保存・管理方法

Dev Container 内で GitHub のリポジトリにアクセスしたり、プライベートなリソースを扱うために、GitHub の Personal Access Token (PAT) を利用することがあります。
本コンテナには GitHub CLI (`gh`) がプリインストールされています。以下の手順で安全に PAT を保存・管理できます。

### 1. PAT の発行

1. GitHub にログインし、`Settings` → `Developer settings` → `Personal access tokens` → `Tokens (classic)` または `Fine-grained tokens` を開きます。
2. 必要なスコープ（`repo` 権限など）を持たせたトークンを発行し、コピーします。

### 2. コンテナ内での PAT の保存

コンテナのターミナルで以下のコマンドを実行し、プロンプトに従って認証を行います。

```bash
gh auth login
```

以下の手順で選択・入力して進めます：

- **What account do you want to log into?** → `GitHub.com`
- **What is your preferred protocol for Git operations?** → `HTTPS`（または `SSH`）
- **Authenticate Git with your GitHub credentials?** → `Yes`
- **How would you like to authenticate GitHub CLI?** → `Paste an authentication token`

最後に、先ほどコピーした PAT をペーストして Enter を押します。

これにより、コンテナ内に GitHub の認証情報が安全に保存され、Git 操作や `gh` コマンドで自動的に認証が行われるようになります。`.env` などに PAT を直接記述・保存する必要がなくなります。
