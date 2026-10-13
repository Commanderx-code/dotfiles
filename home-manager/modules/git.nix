{ machine, ... }:

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
    };
  };
}
