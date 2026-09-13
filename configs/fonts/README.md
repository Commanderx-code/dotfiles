# Fonts

Home Manager installs JetBrains Mono and Meslo LG Nerd Fonts through
`home-manager/modules/fonts.nix`, using the revision pinned in `flake.lock`.
Fontconfig integration makes them available to desktop applications.

The previously bundled TTF files are retired. Existing manually installed fonts
are not removed automatically; review those separately after switching Home Manager.
Upstream attribution files are retained here. Git history still contains the old
binaries; this migration does not rewrite history.
