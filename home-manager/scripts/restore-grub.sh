#!/usr/bin/env bash
# Install the GRUB theme kept in grub/ and the boot settings this configuration
# relies on: the theme, a boot resolution and the kernel parameter that turns
# AppArmor on. Then regenerate the GRUB menu.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
machine_config="${DOTFILES_MACHINE_CONFIG:-$script_dir/../machine.json}"
if [[ ! -f "$machine_config" ]]; then
  machine_config="${DOTFILES_MACHINE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/machine.json}"
fi
DOTFILES_DIR="${DOTFILES_DIR:-$(jq -er '.dotfilesDirectory' "$machine_config")}"
REPO_DIR="$DOTFILES_DIR/grub/cachyos"
# Overridable for fixture tests.
THEME_DIR="${GRUB_THEME_DIR:-/usr/share/grub/themes/cachyos}"
GRUB_DEFAULT="${GRUB_DEFAULT_FILE:-/etc/default/grub}"
GFXMODE="${GRUB_GFXMODE_VALUE:-1920x1080}"
LSM="landlock,lockdown,yama,integrity,apparmor,bpf"

if [[ ! -f "$REPO_DIR/theme.txt" ]]; then
  echo "GRUB theme was not found at: $REPO_DIR" >&2
  exit 1
fi

# The theme: every file, including the distribution icons.
while IFS= read -r -d '' directory; do
  sudo install -d -m755 "$THEME_DIR/${directory#"$REPO_DIR"/}"
done < <(find "$REPO_DIR" -mindepth 1 -type d -print0)
sudo install -d -m755 "$THEME_DIR"
while IFS= read -r -d '' file; do
  sudo install -m644 "$file" "$THEME_DIR/${file#"$REPO_DIR"/}"
done < <(find "$REPO_DIR" -type f -print0)

# The settings, edited on a copy and installed in one step.
work=$(mktemp)
trap 'rm -f -- "$work"' EXIT
if [[ -f "$GRUB_DEFAULT" ]]; then
  cp -- "$GRUB_DEFAULT" "$work"
fi

set_key() {
  local key=$1 value=$2
  if grep -q -E "^#?\s*$key=" "$work"; then
    sed -i -E "s|^#?\s*$key=.*|$key=$value|" "$work"
  else
    printf '%s=%s\n' "$key" "$value" >> "$work"
  fi
}

set_key GRUB_THEME "\"$THEME_DIR/theme.txt\""
# A resolution GRUB can draw the theme at; an explicit choice already there stays.
if ! grep -q -E '^GRUB_GFXMODE=' "$work" || grep -q -E '^GRUB_GFXMODE=("?)auto\1$' "$work"; then
  set_key GRUB_GFXMODE "$GFXMODE"
fi
# AppArmor is only active when the kernel loads it; an lsm= already present is
# the machine's own choice and stays.
if ! grep -q -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$work"; then
  printf 'GRUB_CMDLINE_LINUX_DEFAULT="lsm=%s quiet"\n' "$LSM" >> "$work"
elif ! grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$work" | grep -q 'lsm='; then
  sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=\"?)|\1lsm=$LSM |" "$work"
fi

if [[ -f "$GRUB_DEFAULT" ]] && cmp -s "$work" "$GRUB_DEFAULT"; then
  echo "Boot settings already current: $GRUB_DEFAULT"
else
  sudo install -m644 "$work" "$GRUB_DEFAULT"
  echo "Updated $GRUB_DEFAULT"
fi

if command -v update-grub >/dev/null 2>&1; then
  sudo update-grub
else
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

printf '\nGRUB theme and boot settings installed. They apply at the next reboot.\n'
if command -v aa-enabled >/dev/null 2>&1 && [[ "$(aa-enabled 2>/dev/null || true)" != Yes ]]; then
  echo 'AppArmor becomes active after that reboot; check with aa-enabled.'
fi
