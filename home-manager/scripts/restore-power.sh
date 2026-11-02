#!/usr/bin/env bash
# Install the turbo cap kept in power/cpu-turbo-cap.service as a system unit,
# enable it so the cap applies at every boot, and select the balanced power
# profile; see power/README.md for why.
#
#   restore-power
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
machine_config="${DOTFILES_MACHINE_CONFIG:-$script_dir/../machine.json}"
if [[ ! -f "$machine_config" ]]; then
  machine_config="${DOTFILES_MACHINE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/machine.json}"
fi
DOTFILES_DIR="${DOTFILES_DIR:-$(jq -er '.dotfilesDirectory' "$machine_config")}"
UNIT=cpu-turbo-cap.service
SOURCE="$DOTFILES_DIR/power/$UNIT"
# Overridable for fixture tests.
UNIT_DIR="${SYSTEMD_SYSTEM_DIR:-/etc/systemd/system}"
PSTATE="${INTEL_PSTATE_DIR:-/sys/devices/system/cpu/intel_pstate}"

case "${1:-}" in
  '') ;;
  --help | -h)
    echo 'Usage: restore-power'
    exit 0
    ;;
  *)
    echo 'Usage: restore-power' >&2
    exit 1
    ;;
esac

if [[ ! -f "$SOURCE" ]]; then
  echo "The turbo cap unit was not found at: $SOURCE" >&2
  exit 1
fi
if [[ ! -f "$PSTATE/max_perf_pct" ]]; then
  echo 'This machine has no intel_pstate driver; the unit is installed but stays inactive.' >&2
fi

if [[ -f "$UNIT_DIR/$UNIT" ]] && cmp -s "$SOURCE" "$UNIT_DIR/$UNIT"; then
  echo "Turbo cap unit already current: $UNIT_DIR/$UNIT"
else
  sudo install -D -m644 "$SOURCE" "$UNIT_DIR/$UNIT"
  echo "Installed $UNIT_DIR/$UNIT"
fi
sudo systemctl daemon-reload
# Enabling applies the cap now as well as at every boot.
sudo systemctl enable --now "$UNIT"

if command -v powerprofilesctl >/dev/null 2>&1; then
  if [[ "$(powerprofilesctl get 2>/dev/null || true)" == balanced ]]; then
    echo 'Power profile already balanced.'
  else
    powerprofilesctl set balanced
    echo 'Power profile set to balanced.'
  fi
else
  echo 'power-profiles-daemon is not installed; the power profile was left alone.' >&2
fi

if [[ -f "$PSTATE/max_perf_pct" ]]; then
  echo "Turbo cap in effect: max_perf_pct=$(cat "$PSTATE/max_perf_pct")"
fi
