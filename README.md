# dotfiles

Mac 開発環境のセットアップ一式。

## 対象ツール

| 用途 | ツール |
|------|--------|
| ランタイム管理 | mise (Node / Python / Go / Java) |
| Python パッケージ | uv |
| Rust | rustup |
| CLI ツール | Homebrew (Brewfile) |
| シェル | zsh + Oh My Zsh |

## 新しい Mac でのセットアップ

```bash
git clone https://github.com/shojiiii/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

終わったら `~/.zshrc.local` にプロジェクト固有の設定を追加する。

## Java の複数バージョン切り替え

```bash
# 追加インストール
mise install java@temurin-17

# プロジェクトごとに固定
echo '[tools]\njava = "temurin-17"' > .mise.toml
```

## ファイル構成

| ファイル | 説明 |
|----------|------|
| `.zshrc` | シェル設定 |
| `.zshrc.local.example` | マシン固有設定のテンプレート |
| `Brewfile` | Homebrew パッケージ一覧 |
| `mise.toml` | ランタイムバージョン定義 |
| `bootstrap.sh` | セットアップスクリプト |

`.zshrc.local` は gitignore 済み（プロジェクト固有の環境変数・パスを記載）。
