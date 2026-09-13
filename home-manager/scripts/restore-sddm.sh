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

if [[ ! -d "$REPO_DIR" ]]; then
  echo "Backup directory was not found at: $REPO_DIR" >&2
  exit 1
fi

if [[ ! -d "$THEME_DIR" ]]; then
  echo "SilentSDDM is not installed at: $THEME_DIR" >&2
  echo "Install SilentSDDM first, then run restore-sddm again." >&2
  exit 1
fi

sudo install -d -m755 \
  "$THEME_DIR/configs" \
  "$THEME_DIR/components" \
  "$THEME_DIR/backgrounds" \
  "$SDDM_CONF_DIR"

# Restore presets/configs.
if [[ -d "$REPO_DIR/configs" ]]; then
  while IFS= read -r -d '' file; do
    sudo install -m644 "$file" "$THEME_DIR/configs/$(basename "$file")"
  done < <(find "$REPO_DIR/configs" -maxdepth 1 -type f -print0)
fi

# Restore custom backgrounds, including MP4/JPG/PNG/JPEG files.
if [[ -d "$REPO_DIR/backgrounds" ]]; then
  while IFS= read -r -d '' file; do
    sudo install -m644 "$file" "$THEME_DIR/backgrounds/$(basename "$file")"
  done < <(find "$REPO_DIR/backgrounds" -maxdepth 1 -type f -print0)
fi

# Restore the SilentSDDM files we customized.
for file in BatteryIndicator.qml LoginScreen.qml; do
  if [[ -f "$REPO_DIR/components/$file" ]]; then
    sudo install -m644 "$REPO_DIR/components/$file" "$THEME_DIR/components/$file"
  fi
done

if [[ -f "$REPO_DIR/metadata.desktop" ]]; then
  sudo install -m644 "$REPO_DIR/metadata.desktop" "$THEME_DIR/metadata.desktop"
fi

# Restore SDDM configuration snippets.
if [[ -d "$REPO_DIR/sddm-conf" ]]; then
  while IFS= read -r -d '' file; do
    sudo install -m644 "$file" "$SDDM_CONF_DIR/$(basename "$file")"
  done < <(find "$REPO_DIR/sddm-conf" -maxdepth 1 -type f -print0)
fi

if [[ -f "$REPO_DIR/sddm.conf" ]]; then
  sudo install -m644 "$REPO_DIR/sddm.conf" /etc/sddm.conf
fi

printf '\nSilentSDDM customization restored.\n'
printf 'Current display manager: '
readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true
printf '\nReboot when ready to see the restored login screen.\n'
