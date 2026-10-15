#!/usr/bin/env bash
# Install the GRUB settings kept in grub/grub as /etc/default/grub: the boot
# resolution, a two-second menu, the kernel parameter that turns AppArmor on and
# the chosen look (the Garuda dr460nized theme package, or the CachyOS theme
# kept in grub/themes). Then regenerate the GRUB menu.
#
#   restore-grub [garuda|cachyos]
#
# Without an argument the look comes from ~/.config/dotfiles/boot-theme, then
# from grub/theme.
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
THEMES_DIR="${GRUB_THEMES_DIR:-/usr/share/grub/themes}"
THEME_PACKAGE=grub-theme-garuda-dr460nized

if [[ ! -f "$SOURCE" ]]; then
  echo "GRUB settings were not found at: $SOURCE" >&2
  exit 1
fi

# The look: the argument, the machine's choice, or the repository's default.
look_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/boot-theme"
look="${1:-}"
if [[ -z "$look" && -s "$look_file" ]]; then
  look="$(head -n 1 "$look_file" | tr -d '[:space:]')"
fi
if [[ -z "$look" ]]; then
  look="$(head -n 1 "$DOTFILES_DIR/grub/theme" | tr -d '[:space:]')"
fi
case "$look" in
  garuda | cachyos) ;;
  --help | -h)
    echo 'Usage: restore-grub [garuda|cachyos]'
    exit 0
    ;;
  *)
    echo "Unknown boot menu look '$look'; the looks are garuda and cachyos." >&2
    exit 1
    ;;
esac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
if [[ "$look" == garuda ]]; then
  # The theme is a Garuda package; plain Arch does not carry it.
  if command -v pacman >/dev/null && ! pacman -Q "$THEME_PACKAGE" >/dev/null 2>&1; then
    if pacman -Si "$THEME_PACKAGE" >/dev/null 2>&1; then
      sudo pacman -S --needed "$THEME_PACKAGE"
    else
      echo "The $THEME_PACKAGE package is not in the enabled repositories; GRUB falls back to its plain menu until the theme exists." >&2
    fi
  fi
  cp -- "$SOURCE" "$work/grub"
else
  # The CachyOS theme travels with the repository.
  sudo install -d -m755 -- "$THEMES_DIR/cachyos"
  sudo cp -r --no-preserve=all -- "$DOTFILES_DIR/grub/themes/cachyos/." "$THEMES_DIR/cachyos/"
  sed "s|^GRUB_THEME=.*|GRUB_THEME=\"/usr/share/grub/themes/cachyos/theme.txt\"|" "$SOURCE" > "$work/grub"
fi
SOURCE="$work/grub"
echo "Boot menu look: $look"

theme=$(sed -n 's/^GRUB_THEME="\(.*\)"$/\1/p' "$SOURCE")
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
