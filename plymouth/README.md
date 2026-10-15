# Boot splash

`theme` names the Plymouth theme shown while the system starts. `restore-plymouth`
selects it and rebuilds the boot images that carry it, using the machine's own
initramfs tool (`dracut-rebuild` on Garuda, otherwise `mkinitcpio` or `dracut`).

A theme that is neither installed nor packaged as `plymouth-theme-<name>` can be
kept here as `themes/<name>/`, with `<name>.plymouth` inside, and
`restore-plymouth` installs it. Only add a theme whose license allows
redistribution. The default, `garuda-mac-style-purple`, comes from the KDE Store
through the Boot Splash Screen page in System Settings (Get New).
