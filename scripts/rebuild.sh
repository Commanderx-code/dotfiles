#!/usr/bin/env bash
set -euo pipefail

REPO_SSH="git@github.com:Commanderx-code/dotfiles.git"
REPO_HTTPS="https://github.com/Commanderx-code/dotfiles.git"

echo "[+] Dotfiles rebuild starting..."

echo "[+] Updating apt + installing base tools..."
sudo apt update -y
sudo apt install -y git curl fish flatpak

# Install nala if you want it as your daily driver
sudo apt install -y nala || true

# Install chezmoi if missing
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "[+] Installing chezmoi..."
  if command -v snap >/dev/null 2>&1; then
    sudo snap install chezmoi --classic
  else
    echo "[!] snap not available. Install chezmoi another way (tell me your preference)."
    exit 1
  fi
fi

echo "[+] Initializing chezmoi..."
# Use SSH if it works; fall back to HTTPS
if chezmoi init --apply "$REPO_SSH"; then
  true
else
  chezmoi init --apply "$REPO_HTTPS"
fi

echo "[+] (Optional) Install recommended CLI goodies..."
if command -v nala >/dev/null 2>&1; then
  sudo nala install -y fzf ripgrep ffmpeg || true
else
  sudo apt install -y fzf ripgrep ffmpeg || true
fi

echo "[+] Setting default shell to fish (logout/login after)..."
if command -v fish >/dev/null 2>&1; then
  chsh -s "$(command -v fish)" "$USER" || true
fi

echo "[✓] Done. Open a new terminal."
