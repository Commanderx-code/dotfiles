#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
machine_config="${DOTFILES_MACHINE_CONFIG:-$script_dir/../machine.json}"
if [[ ! -f "$machine_config" ]]; then
  machine_config="${DOTFILES_MACHINE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/machine.json}"
fi
DOTFILES_DIR="${DOTFILES_DIR:-$(jq -er '.dotfilesDirectory' "$machine_config")}"
REPO_DIR="$DOTFILES_DIR/sddm"
THEME_DIR="/usr/share/sddm/themes/silent"
SDDM_CONF_DIR="/etc/sddm.conf.d"

if [[ ! -d "$THEME_DIR" ]]; then
  echo "SilentSDDM was not found at: $THEME_DIR" >&2
  exit 1
fi

mkdir -p \
  "$REPO_DIR/configs" \
  "$REPO_DIR/components" \
  "$REPO_DIR/backgrounds" \
  "$REPO_DIR/sddm-conf"

# Presets/configs and backgrounds. These are intentionally copied in full so
# custom presets/media you add later are automatically included.
cp -a "$THEME_DIR/configs/." "$REPO_DIR/configs/"
cp -a "$THEME_DIR/backgrounds/." "$REPO_DIR/backgrounds/"

# Files we customized in SilentSDDM.
cp -a "$THEME_DIR/components/BatteryIndicator.qml" "$REPO_DIR/components/"
cp -a "$THEME_DIR/components/LoginScreen.qml" "$REPO_DIR/components/"
cp -a "$THEME_DIR/metadata.desktop" "$REPO_DIR/"

# SDDM configuration.
cp -a "$SDDM_CONF_DIR/." "$REPO_DIR/sddm-conf/"

# /etc/sddm.conf is optional; save it only if it exists and is non-empty.
if [[ -s /etc/sddm.conf ]]; then
  cp -a /etc/sddm.conf "$REPO_DIR/sddm.conf"
else
  rm -f "$REPO_DIR/sddm.conf"
fi

printf '\nSDDM backup synced to:\n  %s\n\n' "$REPO_DIR"
printf 'Next:\n  cd %s\n  git status\n' "$DOTFILES_DIR"
