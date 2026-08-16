if status is-interactive
    if not ssh-add -l >/dev/null 2>&1
        set -lx SSH_ASKPASS /usr/bin/ksshaskpass
        set -lx SSH_ASKPASS_REQUIRE force
        ssh-add ~/.ssh/id_ed25519 </dev/null
    end
end
