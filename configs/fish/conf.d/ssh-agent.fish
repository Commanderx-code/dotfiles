# The agent comes from the ssh-agent.socket user unit. Without that socket, or
# without a key to load, there is nothing to do and no error to show.
set -l socket "$XDG_RUNTIME_DIR/ssh-agent.socket"
if not test -S "$socket"
    return
end
set -gx SSH_AUTH_SOCK "$socket"

if status is-interactive; and test -f ~/.ssh/id_ed25519
    if not ssh-add -l >/dev/null 2>&1
        # KDE's prompt reads the passphrase from KWallet; without it ssh-add
        # asks in the terminal as usual.
        if test -x /usr/bin/ksshaskpass
            SSH_ASKPASS=/usr/bin/ksshaskpass SSH_ASKPASS_REQUIRE=force ssh-add ~/.ssh/id_ed25519 </dev/null
        else
            ssh-add ~/.ssh/id_ed25519
        end
    end
end
