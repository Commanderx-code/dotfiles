{ machine, ... }:
{
  xdg.configFile."topgrade.toml".text =
    builtins.replaceStrings
      [ "@HOME_MANAGER_FLAKE@" "@DOTFILES_DIRECTORY@" ]
      [
        (builtins.toJSON "${machine.dotfilesDirectory}/home-manager#${machine.username}")
        (builtins.toJSON machine.dotfilesDirectory)
      ]
      (builtins.readFile ../../configs/topgrade/topgrade.toml);
}
