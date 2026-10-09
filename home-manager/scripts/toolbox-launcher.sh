#!/usr/bin/env bash
# Run Commander Toolbox from its latest published release, replacing the cached
# copy first when a newer build exists. Offline, the cached copy runs as it is.
set -euo pipefail

# A personal launcher, such as one running a source checkout, takes precedence.
personal=$HOME/.local/bin/commander-toolbox
if [[ -x "$personal" && ! "$personal" -ef "$0" ]]; then
  exec "$personal" "$@"
fi

base=https://github.com/Commanderx-code/commander-toolbox/releases/latest/download
asset=commander-toolbox-linux-x86_64
directory=${XDG_DATA_HOME:-$HOME/.local/share}/commander-toolbox
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
  echo 'Updating Commander Toolbox...' >&2
  fetch --max-time 300 -o "$work/$asset" "$base/$asset" || return 1
  if [[ $(checksum "$work/$asset") != "$expected" ]]; then
    echo 'The downloaded Toolbox did not match its published checksum; it was discarded.' >&2
    return 1
  fi
  chmod 755 "$work/$asset"
  mv -f -- "$work/$asset" "$binary"
}

mkdir -p "$directory"
work=$(mktemp -d "$directory/update.XXXXXX")
update "$work" || echo 'Could not update Commander Toolbox; using the installed copy.' >&2
rm -rf -- "$work"

if [[ ! -x "$binary" ]]; then
  echo 'Commander Toolbox is not downloaded yet; connect to the internet and try again.' >&2
  exit 1
fi
exec "$binary" "$@"
