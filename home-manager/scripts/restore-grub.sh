#!/usr/bin/env bash
# Install the GRUB settings kept in grub/grub as /etc/default/grub: the Garuda
# dr460nized theme, the boot resolution, a two-second menu and the kernel
# parameter that turns AppArmor on. Then regenerate the GRUB menu.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
machine_config="${DOTFILES_MACHINE_CONFIG:-$script_dir/../machine.json}"
if [[ ! -f "$machine_config" ]]; then
  machine_config="${DOTFILES_MACHINE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/machine.json}"
fi
DOTFILES_DIR="${DOTFILES_DIR:-$(jq -er '.dotfilesDirectory' "$machine_config")}"
SOURCE="$DOTFILES_DIR/grub/grub"
# Overridable for fixture tests.
GRUB_DEFAULT="${GRUB_DEFAULT_FILE:-/etc/default/grub}"
THEME_PACKAGE=grub-theme-garuda-dr460nized

if [[ ! -f "$SOURCE" ]]; then
  echo "GRUB settings were not found at: $SOURCE" >&2
  exit 1
fi

# The theme is a Garuda package; plain Arch does not carry it.
theme=$(sed -n 's/^GRUB_THEME="\(.*\)"$/\1/p' "$SOURCE")
if command -v pacman >/dev/null && ! pacman -Q "$THEME_PACKAGE" >/dev/null 2>&1; then
  if pacman -Si "$THEME_PACKAGE" >/dev/null 2>&1; then
    sudo pacman -S --needed "$THEME_PACKAGE"
  else
    echo "The $THEME_PACKAGE package is not in the enabled repositories; GRUB falls back to its plain menu until the theme exists." >&2
  fi
fi
if [[ -n "$theme" && ! -f "${GRUB_THEME_ROOT:-}$theme" ]]; then
  echo "Theme file missing: $theme" >&2
fi
kernel=$(sed -n 's/^GRUB_TOP_LEVEL="\(.*\)"$/\1/p' "$SOURCE")
if [[ -n "$kernel" && ! -e "${GRUB_THEME_ROOT:-}$kernel" ]]; then
  echo "GRUB_TOP_LEVEL names $kernel, which this machine does not have; the menu keeps its usual order." >&2
fi

if [[ -f "$GRUB_DEFAULT" ]] && cmp -s "$SOURCE" "$GRUB_DEFAULT"; then
  echo "Boot settings already current: $GRUB_DEFAULT"
else
  # The machine's previous settings stay beside the new ones, once.
  if [[ -f "$GRUB_DEFAULT" && ! -f "$GRUB_DEFAULT.before-dotfiles" ]]; then
    sudo cp -- "$GRUB_DEFAULT" "$GRUB_DEFAULT.before-dotfiles"
    echo "Previous settings kept at $GRUB_DEFAULT.before-dotfiles"
  fi
  sudo install -m644 "$SOURCE" "$GRUB_DEFAULT"
  echo "Installed $GRUB_DEFAULT"
fi

if command -v update-grub >/dev/null 2>&1; then
  sudo update-grub
else
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

printf '\nGRUB settings installed. They apply at the next reboot.\n'
if command -v aa-enabled >/dev/null 2>&1 && [[ "$(aa-enabled 2>/dev/null || true)" != Yes ]]; then
  echo 'AppArmor becomes active after that reboot; check with aa-enabled.'
fi
