#!/usr/bin/env bash
# Install a boot menu look kept in limine/themes (a wallpaper and appearance
# settings) into the machine's limine.conf, and the kernel parameters in
# limine/cmdline into /etc/default/limine, where the Limine entry tool reads
# them on CachyOS. The boot entries themselves are never touched.
#
#   restore-limine [garuda|cachyos] [--menu-only]
#
# Without a look the choice comes from ~/.config/dotfiles/boot-theme, then
# from limine/theme.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
machine_config="${DOTFILES_MACHINE_CONFIG:-$script_dir/../machine.json}"
if [[ ! -f "$machine_config" ]]; then
  machine_config="${DOTFILES_MACHINE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/machine.json}"
fi
DOTFILES_DIR="${DOTFILES_DIR:-$(jq -er '.dotfilesDirectory' "$machine_config")}"
SOURCE_DIR="$DOTFILES_DIR/limine"
RENDER="$script_dir/limine-config.py"
# Overridable for fixture tests.
LIMINE_DEFAULT="${LIMINE_DEFAULT_FILE:-/etc/default/limine}"
WALLPAPER=dotfiles-splash.png

menu_only=false
look=''
for argument in "$@"; do
  case "$argument" in
    --menu-only) menu_only=true ;;
    --help | -h)
      echo 'Usage: restore-limine [garuda|cachyos] [--menu-only]'
      echo 'Installs a boot menu look from limine/themes and, unless --menu-only, the'
      echo 'kernel parameters in limine/cmdline through /etc/default/limine.'
      exit 0
      ;;
    garuda | cachyos) look=$argument ;;
    *) echo "Unknown argument: $argument" >&2; exit 1 ;;
  esac
done
# The look: the argument, the machine's choice, or the repository's default.
look_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/boot-theme"
if [[ -z "$look" && -s "$look_file" ]]; then
  look="$(head -n 1 "$look_file" | tr -d '[:space:]')"
fi
if [[ -z "$look" ]]; then
  look="$(head -n 1 "$SOURCE_DIR/theme" | tr -d '[:space:]')"
fi
case "$look" in
  garuda | cachyos) ;;
  *) echo "Unknown boot menu look '$look'; the looks are garuda and cachyos." >&2; exit 1 ;;
esac
LOOK_DIR="$SOURCE_DIR/themes/$look"
for file in "$LOOK_DIR/limine.conf" "$LOOK_DIR/splash.png" "$SOURCE_DIR/cmdline"; do
  if [[ ! -f "$file" ]]; then
    echo "Limine settings were not found at: $file" >&2
    exit 1
  fi
done
echo "Boot menu look: $look"

# limine.conf lives on the boot partition, which may be readable by root only.
find_limine_conf() {
  if [[ -n "${LIMINE_CONF:-}" ]]; then
    printf '%s\n' "$LIMINE_CONF"
    return
  fi
  local esp='' dir
  if [[ -f "$LIMINE_DEFAULT" ]]; then
    esp=$(sed -n 's/^ESP_PATH=["'\'']\{0,1\}\([^"'\'' ]*\).*/\1/p' "$LIMINE_DEFAULT" | tail -n 1)
  fi
  for dir in ${esp:+"$esp"} /boot /efi /boot/efi /boot/limine /boot/EFI/limine /boot/efi/limine; do
    if sudo test -f "$dir/limine.conf"; then
      printf '%s\n' "$dir/limine.conf"
      return
    fi
  done
  return 1
}

conf=$(find_limine_conf) || {
  echo 'limine.conf was not found under /boot, /efi or /boot/efi; this machine does not seem to boot with Limine.' >&2
  echo 'Set LIMINE_CONF to its path if it lives elsewhere.' >&2
  exit 1
}
conf_dir=$(dirname -- "$conf")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The wallpaper goes beside limine.conf, where boot():/ resolves.
if sudo test -f "$conf_dir/$WALLPAPER" && sudo cmp -s "$LOOK_DIR/splash.png" "$conf_dir/$WALLPAPER"; then
  :
else
  sudo install -m644 -- "$LOOK_DIR/splash.png" "$conf_dir/$WALLPAPER"
  echo "Installed $conf_dir/$WALLPAPER"
fi

# The copy lands in this user's work directory; only the read needs root.
# shellcheck disable=SC2024
sudo cat -- "$conf" > "$work/current.conf"
python3 -I "$RENDER" appearance "$work/current.conf" "$LOOK_DIR/limine.conf" > "$work/limine.conf"
if cmp -s "$work/limine.conf" "$work/current.conf"; then
  echo "Boot menu already current: $conf"
else
  # The machine's previous settings stay beside the new ones, once.
  if ! sudo test -f "$conf.before-dotfiles"; then
    sudo cp -- "$conf" "$conf.before-dotfiles"
    echo "Previous settings kept at $conf.before-dotfiles"
  fi
  sudo install -m644 -- "$work/limine.conf" "$conf"
  echo "Installed the boot menu appearance into $conf"
fi

if "$menu_only"; then
  printf '\nLimine boot menu installed. It shows at the next reboot.\n'
  exit 0
fi

# Kernel parameters, read by the entry tool from /etc/default/limine.
mapfile -t words < <(grep -v '^[[:space:]]*#' "$SOURCE_DIR/cmdline" | tr -s '[:space:]' '\n' | grep .)
if [[ ! -f "$LIMINE_DEFAULT" ]]; then
  echo "No $LIMINE_DEFAULT: the boot entries are written by hand here. Add ${words[*]} to their cmdline lines in $conf yourself." >&2
elif ! python3 -I "$RENDER" cmdline "$LIMINE_DEFAULT" set "${words[@]}" > "$work/default" 2> "$work/error"; then
  echo "$LIMINE_DEFAULT was not changed: $(cat "$work/error")" >&2
elif cmp -s "$work/default" "$LIMINE_DEFAULT"; then
  echo "Kernel parameters already current: $LIMINE_DEFAULT"
else
  if [[ ! -f "$LIMINE_DEFAULT.before-dotfiles" ]]; then
    sudo cp -- "$LIMINE_DEFAULT" "$LIMINE_DEFAULT.before-dotfiles"
    echo "Previous settings kept at $LIMINE_DEFAULT.before-dotfiles"
  fi
  sudo install -m644 -- "$work/default" "$LIMINE_DEFAULT"
  echo "Installed $LIMINE_DEFAULT with ${words[*]}"
  # The entry tool writes the parameters into the entries when it regenerates
  # them, which also rebuilds the boot images.
  if command -v limine-mkinitcpio >/dev/null 2>&1; then
    sudo limine-mkinitcpio
  elif command -v limine-dracut >/dev/null 2>&1; then
    sudo limine-dracut
  else
    echo 'Regenerate the boot entries with the Limine entry tool so the parameters reach them.' >&2
  fi
fi

printf '\nLimine boot menu installed. It shows at the next reboot.\n'
if command -v aa-enabled >/dev/null 2>&1 && [[ "$(aa-enabled 2>/dev/null || true)" != Yes ]]; then
  echo 'AppArmor becomes active after that reboot; check with aa-enabled.'
fi
