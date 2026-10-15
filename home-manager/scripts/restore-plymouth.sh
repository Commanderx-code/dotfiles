#!/usr/bin/env bash
# Select the Plymouth boot splash named in plymouth/theme and rebuild the boot
# images that carry it, with whichever initramfs tool the machine uses. The
# Boot Splash Screen page in System Settings only does the first half on
# Garuda, because it rebuilds with mkinitcpio and Garuda uses dracut.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: restore-plymouth [THEME]     select THEME; default: the theme named in plymouth/theme
       restore-plymouth --rebuild   keep the current theme and rebuild the boot images
USAGE
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
machine_config="${DOTFILES_MACHINE_CONFIG:-$script_dir/../machine.json}"
if [[ ! -f "$machine_config" ]]; then
  machine_config="${DOTFILES_MACHINE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/machine.json}"
fi
DOTFILES_DIR="${DOTFILES_DIR:-$(jq -er '.dotfilesDirectory' "$machine_config")}"
# Overridable for fixture tests.
THEMES_DIR="${PLYMOUTH_THEMES_DIR:-/usr/share/plymouth/themes}"

rebuild_only=false
theme=''
for arg in "$@"; do
  case "$arg" in
    --rebuild) rebuild_only=true ;;
    -h | --help) usage; exit 0 ;;
    -*) usage >&2; exit 2 ;;
    *) theme=$arg ;;
  esac
done
if "$rebuild_only" && [[ -n "$theme" ]]; then
  echo 'Give either a theme name or --rebuild, not both.' >&2
  exit 2
fi

if ! command -v plymouth-set-default-theme >/dev/null; then
  echo 'Plymouth is not installed; there is no boot splash to set.' >&2
  exit 1
fi
current=$(plymouth-set-default-theme)

if "$rebuild_only"; then
  theme=$current
else
  if [[ -z "$theme" ]]; then
    source="$DOTFILES_DIR/plymouth/theme"
    if [[ ! -f "$source" ]]; then
      echo "No boot splash is named at: $source" >&2
      exit 1
    fi
    theme=$(head -n 1 "$source" | tr -d '[:space:]')
  fi
  if [[ ! "$theme" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "A theme name has only letters, digits, dots, dashes and underscores: $theme" >&2
    exit 1
  fi

  if [[ ! -f "$THEMES_DIR/$theme/$theme.plymouth" ]]; then
    if [[ -f "$DOTFILES_DIR/plymouth/themes/$theme/$theme.plymouth" ]]; then
      sudo cp -r -- "$DOTFILES_DIR/plymouth/themes/$theme" "$THEMES_DIR/"
      echo "Installed $THEMES_DIR/$theme from the repository"
    elif command -v pacman >/dev/null && pacman -Si "plymouth-theme-$theme" >/dev/null 2>&1; then
      sudo pacman -S --needed "plymouth-theme-$theme"
    else
      cat >&2 <<MESSAGE
The theme '$theme' is not installed, and neither the repository (plymouth/themes/$theme)
nor the package repositories (plymouth-theme-$theme) carry it. The Boot Splash Screen
page in System Settings fetches themes with Get New; run restore-plymouth again afterwards.
The boot splash stays '$current'.
MESSAGE
      exit 1
    fi
  fi

  if [[ "$theme" == "$current" ]]; then
    echo "Boot splash already current: $theme"
    echo 'restore-plymouth --rebuild puts it into the boot images again if they lack it.'
    exit 0
  fi
  sudo plymouth-set-default-theme "$theme"
  echo "Selected boot splash: $theme"
fi

# The splash is read from the initramfs, so the boot images must be rebuilt.
if command -v dracut-rebuild >/dev/null; then
  sudo dracut-rebuild
elif command -v mkinitcpio >/dev/null; then
  sudo mkinitcpio -P
elif command -v dracut >/dev/null; then
  sudo dracut --force --regenerate-all
else
  echo 'No initramfs tool was found; rebuild the boot images yourself so the splash reaches them.' >&2
  exit 1
fi

printf '\nBoot splash %s shows from the next reboot.\n' "$theme"
