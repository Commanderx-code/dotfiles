{ machine, lib, pkgs, ... }:

let
  # Rejects a commit message that credits an AI tool. Only the message counts:
  # comment lines go, and so does the diff commit.verbose adds below the scissors.
  noAiAttribution = pkgs.writeShellApplication {
    name = "no-ai-attribution";
    runtimeInputs = [
      pkgs.gnugrep
      pkgs.gnused
    ];
    text = ''
      found=$(sed '/^# -\{24\} >8 -\{24\}$/,$d' "$1" | grep -v '^#' \
        | grep -inE 'co-authored-by:.*(claude|anthropic)|^claude-session:|generated with \[?claude code|noreply@anthropic\.com|claude\.ai/code/session_' || true)
      if [[ -n "$found" ]]; then
        echo "commit-msg: remove the AI attribution from the commit message:" >&2
        printf '  %s\n' "$found" >&2
        exit 1
      fi
    '';
  };
in
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = machine.gitName;
        email = machine.gitEmail;
      };

      init.defaultBranch = "main";
      pull.rebase = false;

      # Forget remote branches that were deleted on the server.
      fetch.prune = true;
      # A first push of a new branch needs no --set-upstream.
      push.autoSetupRemote = true;

      # Conflicts show the original text between the two sides.
      merge.conflictStyle = "zdiff3";
      diff.algorithm = "histogram";
      # Remember how a conflict was resolved and reuse it if it returns.
      rerere.enabled = true;

      # Most recently used branches first.
      branch.sort = "-committerdate";
      # Show the diff while writing a commit message.
      commit.verbose = true;
      rebase.autoStash = true;

      # A configured hook runs in every repository, alongside its own .git/hooks.
      hook.no-ai-attribution = {
        event = "commit-msg";
        command = "${noAiAttribution}/bin/no-ai-attribution";
      };
    };

    # Written at activation, and only on a machine that has the SSH key; Git
    # ignores an include that does not exist.
    includes = [ { path = "~/.config/git/signing.inc"; } ];
  };

  # Sign commits and tags with the SSH key the agent already holds. The settings
  # live outside the Nix store because they depend on a key that is not in this
  # repository: without ~/.ssh/id_ed25519.pub nothing is signed and nothing fails.
  home.activation.gitSigning = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    key="$HOME/.ssh/id_ed25519.pub"
    directory="''${XDG_CONFIG_HOME:-$HOME/.config}/git"
    if [[ ! -v DRY_RUN ]]; then
      if [[ -f "$key" ]]; then
        mkdir -p "$directory"
        # Who may sign as this identity, for `git log --show-signature`.
        printf '%s namespaces="git" %s\n' ${lib.escapeShellArg machine.gitEmail} "$(cut -d' ' -f1,2 "$key")" > "$directory/allowed_signers"
        printf '%s\n' \
          '[gpg]' '  format = ssh' \
          '[gpg "ssh"]' "  allowedSignersFile = $directory/allowed_signers" \
          '[user]' "  signingKey = $key" \
          '[commit]' '  gpgSign = true' \
          '[tag]' '  gpgSign = true' > "$directory/signing.inc"
      else
        rm -f "$directory/signing.inc" "$directory/allowed_signers"
      fi
    fi
  '';
}
