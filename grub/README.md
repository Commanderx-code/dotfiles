# GRUB settings

`grub` is the complete `/etc/default/grub` that `restore-grub` installs: a
two-second menu, the boot resolution, the kernel parameter that turns AppArmor
on, and the theme. Two looks are kept, and `theme` names the default (`garuda`):

| Look | Where it comes from |
| :--- | :--- |
| `garuda` | The `grub-theme-garuda-dr460nized` package from Garuda's repositories, which `restore-grub` installs when the repositories have it. |
| `cachyos` | `themes/cachyos/`, the [CachyOS GRUB theme](https://github.com/diegons490/cachyos-grub-theme) by diegons490 (GPL-3.0, `LICENSE` kept there), copied to `/usr/share/grub/themes/cachyos`. |

Pick a look for one run with `restore-grub cachyos`, or permanently by putting
its name in `~/.config/dotfiles/boot-theme`, the file `restore-limine` reads as
well, so a machine keeps one choice whichever boot loader it has. `restore-grub`
rewrites only the `GRUB_THEME` line for the chosen look; everything else in
`grub` is installed as it is, with the machine's previous file kept once as
`/etc/default/grub.before-dotfiles`.
