{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Commanderx-code";
        email = "65996567+Commanderx-code@users.noreply.github.com";
      };

      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
