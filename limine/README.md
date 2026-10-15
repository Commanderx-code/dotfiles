# Limine boot menu

`restore-limine` gives a machine that boots with Limine, such as a CachyOS
install, the same boot setup that `restore-grub` gives a GRUB machine. Limine
has no theme packages: its menu is styled by a wallpaper and a few colour and
timeout settings, so a look here is one folder under `themes/`:

| Look | Folder | What it is |
| :--- | :--- | :--- |
| `cachyos` | `themes/cachyos/` | The [CachyOS Limine theme](https://github.com/diegons490/cachyos-limine-theme) by diegons490: wallpaper and Catppuccin-style colours. GPL-3.0; its `LICENSE` is kept there. |
| `garuda` | `themes/garuda/` | Garuda's dr460nized look: the wallpaper and colours of the `grub-theme-garuda-dr460nized` package (GPL), so a Limine machine can match a Garuda one. |

Each folder holds `limine.conf`, the appearance settings, and `splash.png`, the
wallpaper. `theme` names the look used by default (`cachyos`); a machine picks
another with `restore-limine garuda`, or permanently by putting the name in
`~/.config/dotfiles/boot-theme`, the same file `restore-grub` reads.

What `restore-limine` does:

- Finds the machine's `limine.conf` through `ESP_PATH` in `/etc/default/limine`,
  or under `/boot`, `/efi` or `/boot/efi`, copies the wallpaper beside it as
  `dotfiles-splash.png`, and merges the settings into the global section. The
  boot entries, the lines starting with `/`, stay as the machine has them; on
  CachyOS the Limine entry tool manages them.
- Sets the kernel parameters in `cmdline` (the one that turns AppArmor on) in
  `KERNEL_CMDLINE[default]` of `/etc/default/limine`, where the entry tool reads
  them, then regenerates the entries with `limine-mkinitcpio` (or
  `limine-dracut`), which also rebuilds the boot images. Without
  `/etc/default/limine` the entries are hand-written, and `restore-limine` says
  which parameters to add yourself. `--menu-only` skips this step.

The previous `limine.conf` and `/etc/default/limine` are kept once beside the
new ones with a `.before-dotfiles` suffix. A GRUB theme's layout files cannot
be used by Limine, which is why the looks are settings rather than theme folders.
