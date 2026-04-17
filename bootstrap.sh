#!/usr/bin/env bash
# New Mac setup: run once after cloning dotfiles
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "==> Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "==> Brew packages"
brew bundle --file="$DOTFILES/Brewfile"

echo "==> mise: install runtimes"
cp "$DOTFILES/mise.toml" ~/.config/mise/config.toml
mise install

echo "==> Rust toolchain"
rustup-init -y --no-modify-path
rustup default stable

echo "==> .zshrc"
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d)
cp "$DOTFILES/.zshrc" ~/.zshrc

echo "==> .zshrc.local (machine-specific, gitignored)"
if [ ! -f ~/.zshrc.local ]; then
  cp "$DOTFILES/.zshrc.local.example" ~/.zshrc.local
  echo "  Edit ~/.zshrc.local with your project paths and secrets"
fi

echo ""
echo "Done! Open a new terminal to activate."
echo ""
echo "Java: default is temurin-21"
echo "  Extra versions:  mise install java@temurin-17"
echo "  Per project:     echo '[tools]\njava = \"temurin-17\"' > .mise.toml"
