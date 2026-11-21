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
