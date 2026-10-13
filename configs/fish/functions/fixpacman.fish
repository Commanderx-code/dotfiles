function fixpacman --description 'Remove a stale pacman lock'
    set -l lock /var/lib/pacman/db.lck
    if not test -e $lock
        echo 'No pacman lock to remove.'
        return 0
    end
    # Removing the lock under a running pacman can corrupt its database.
    if pgrep -x pacman >/dev/null
        echo 'pacman is running; wait for it to finish or stop it first.' >&2
        return 1
    end
    command sudo rm -f -- $lock
end
