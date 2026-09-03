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
| `.claude/` | Claude Code の共有設定・skills・hooks |

`.zshrc.local` は gitignore 済み（プロジェクト固有の環境変数・パスを記載）。

`.claude/` は allowlist 方式で管理しており、`.gitignore`、`settings.json`、`skills/`、`hooks/` のみを追跡する。セッション履歴・キャッシュ・認証情報などの実行時データは追跡しない。

Claude Code の共有設定と `mise.toml` の変更は、macOS の LaunchAgent が検知して `main` へ自動 commit/push する。push 前に高確度の鍵・トークン・PEM 秘密鍵パターンを検査し、検出時は commit/push を中止する。新しい Mac では `./bootstrap.sh` がこの LaunchAgent を登録する。
