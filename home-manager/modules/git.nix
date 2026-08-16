{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Commanderx-code";
        email = "dirtyprodigy@protonmail.com";
      };

      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
