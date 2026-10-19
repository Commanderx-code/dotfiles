#!/usr/bin/env bash
# Run Helix Toolbox (HelixForge before 1.7) from its latest published release, replacing the cached copy
# first when a newer build exists. Offline, the cached copy runs as it is.
set -euo pipefail

# A personal launcher, such as one running a source checkout, takes precedence.
for personal in "$HOME/.local/bin/helix-toolbox" "$HOME/.local/bin/helixforge"; do
  if [[ -x "$personal" && ! "$personal" -ef "$0" ]]; then
    exec "$personal" "$@"
  fi
done

# Releases have a build for each of these processors.
case $(uname -m) in
  x86_64) asset=helix-toolbox-linux-x86_64 ;;
  aarch64 | arm64) asset=helix-toolbox-linux-aarch64 ;;
  *)
    echo "Helix Toolbox has no build for this processor ($(uname -m))." >&2
    exit 1
    ;;
esac
base=https://github.com/Commanderx-code/Helix-toolbox/releases/latest/download
directory=${XDG_DATA_HOME:-$HOME/.local/share}/helix-toolbox
binary=$directory/$asset

fetch() {
  curl --fail --silent --location --proto '=https' --tlsv1.2 --connect-timeout 5 "$@"
}

checksum() {
  local sum
  sum=$(sha256sum -- "$1") || return 1
  printf '%s\n' "${sum%% *}"
}

update() {
  local work=$1 expected='' sum name
  fetch --max-time 20 -o "$work/SHA256SUMS" "$base/SHA256SUMS" || return 1
  while read -r sum name; do
    [[ "${name#\*}" == "$asset" ]] && expected=$sum
  done <"$work/SHA256SUMS"
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || return 1
  if [[ -x "$binary" && $(checksum "$binary") == "$expected" ]]; then
    return 0
  fi
  echo 'Updating Helix Toolbox...' >&2
  fetch --max-time 300 -o "$work/$asset" "$base/$asset" || return 1
  if [[ $(checksum "$work/$asset") != "$expected" ]]; then
    echo 'The downloaded Helix Toolbox did not match its published checksum; it was discarded.' >&2
    return 1
  fi
  chmod 755 "$work/$asset"
  mv -f -- "$work/$asset" "$binary"
}

mkdir -p "$directory"
work=$(mktemp -d "$directory/update.XXXXXX")
update "$work" || echo 'Could not update Helix Toolbox; using the installed copy.' >&2
rm -rf -- "$work"

if [[ ! -x "$binary" ]]; then
  echo 'Helix Toolbox is not downloaded yet; connect to the internet and try again.' >&2
  exit 1
fi
exec "$binary" "$@"
