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
    };
  };
}
