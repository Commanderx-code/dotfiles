# Limine boot menu

`restore-limine` gives a machine that boots with Limine, such as a CachyOS
install, the same boot setup that `restore-grub` gives a GRUB machine:

- `limine.conf` holds the appearance settings: the wallpaper, colours and
  two-second timeout. They are merged into the global section of the machine's
  `limine.conf` (found through `ESP_PATH` in `/etc/default/limine`, or under
  `/boot`, `/efi` or `/boot/efi`). The boot entries, the lines starting with `/`,
  stay as the machine has them; on CachyOS the Limine entry tool manages them.
- `dotfiles-splash.png` is the wallpaper, copied beside `limine.conf`.
- `cmdline` lists kernel parameters to set in `KERNEL_CMDLINE[default]` of
  `/etc/default/limine`, where the entry tool reads them. After a change the
  entries are regenerated with `limine-mkinitcpio` (or `limine-dracut`), which
  also rebuilds the boot images. Without `/etc/default/limine` the entries are
  hand-written, and `restore-limine` says which parameters to add yourself.

The previous `limine.conf` and `/etc/default/limine` are kept once beside the
new ones with a `.before-dotfiles` suffix. `restore-limine --menu-only` changes
the appearance and leaves the kernel parameters alone.

The wallpaper and colours are the
[CachyOS Limine theme](https://github.com/diegons490/cachyos-limine-theme) by
diegons490, the Limine counterpart of the author's
[CachyOS GRUB theme](https://github.com/diegons490/cachyos-grub-theme); both are
GPL-3.0, and the license is kept here as `LICENSE`. A GRUB theme's layout files
cannot be used by Limine, whose menu is styled only by these settings.
