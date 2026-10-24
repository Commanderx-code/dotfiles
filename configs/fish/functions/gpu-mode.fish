function gpu-mode --description 'Switch between Intel-only and hybrid graphics (EnvyControl); reboot afterward'
    # The NVIDIA card can't power itself off on this laptop (no runtime D3),
    # so integrated mode hides it from the system instead. EnvyControl writes
    # the driver blacklist and the udev rule that removes the card, but then
    # calls mkinitcpio, which Garuda doesn't have, and fails; the boot images
    # are rebuilt here with Garuda's dracut-rebuild instead.
    set -l blacklist /etc/modprobe.d/blacklist-nvidia.conf
    # Garuda's NVIDIA profile loads nvidia-drm at every boot; a link to
    # /dev/null with the same name in /etc masks that file while the
    # driver is blocked.
    set -l autoload /etc/modules-load.d/garuda-nvidia.conf

    switch "$argv[1]"
        case integrated
            if not command -q envycontrol
                echo 'EnvyControl is not installed: sudo pacman -S envycontrol' >&2
                return 1
            end
            command sudo envycontrol -s integrated 2>/dev/null
            if not test -f $blacklist
                echo 'EnvyControl did not write its blacklist; nothing else changed.' >&2
                return 1
            end
            command sudo ln -sf /dev/null $autoload
            or return 1
            command sudo dracut-rebuild
            or return 1
        case hybrid
            if not command -q envycontrol
                echo 'EnvyControl is not installed: sudo pacman -S envycontrol' >&2
                return 1
            end
            # --reset removes only EnvyControl's own files: back to Garuda's setup.
            command sudo envycontrol --reset 2>/dev/null
            if test -f $blacklist
                echo 'EnvyControl did not remove its blacklist; nothing else changed.' >&2
                return 1
            end
            command sudo rm -f $autoload
            or return 1
            command sudo dracut-rebuild
            or return 1
        case '' status
            if command -q envycontrol
                echo "Graphics mode: "(envycontrol -q)
            else
                echo 'Graphics mode: hybrid (EnvyControl is not installed)'
            end
            return 0
        case '*'
            echo 'Usage: gpu-mode [status | integrated | hybrid]' >&2
            return 1
    end
    echo "Switched to $argv[1] graphics. Reboot to finish."
end
