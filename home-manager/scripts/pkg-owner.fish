#!/usr/bin/env fish

if test (count $argv) -ne 1
    echo "Usage: pkg-owner <command>"
    exit 1
end

set -l NAME "$argv[1]"
set -l CMD (command -s "$NAME" 2>/dev/null)

if test -z "$CMD"
    echo "Command not found: $NAME"
    exit 1
end

set -l REAL (readlink -f "$CMD" 2>/dev/null)

echo "Command:"
echo "  $NAME"
echo

echo "Resolved path:"
echo "  $REAL"
echo

if string match -q '/nix/store/*' "$REAL"
    echo "Owner:"
    echo "  Nix / Home Manager"
    echo

    set -l STORE_PATH (
        string match -r '^/nix/store/[^/]+' "$REAL"
    )

    if test -n "$STORE_PATH"
        echo "Nix store path:"
        echo "  $STORE_PATH"
    end

    exit 0
end

if command -q pacman
    set -l PACMAN_OWNER (
        pacman -Qo "$REAL" 2>/dev/null
    )

    if test $status -eq 0
        echo "Owner:"
        echo "  Pacman"
        echo
        echo "$PACMAN_OWNER"
        exit 0
    end
end

if string match -q "$HOME/.local/*" "$REAL"
    echo "Owner:"
    echo "  User-local / Home Manager helper / manually installed"
    echo
    echo "Check:"
    echo "  ls -l \"$CMD\""
    exit 0
end

echo "Owner:"
echo "  Unknown / manually installed"
echo
echo "Pacman does not own this path and it is not inside /nix/store."
