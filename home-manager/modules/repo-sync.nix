{
  machine,
  pkgs,
  lib,
  ...
}:
let
  checks = pkgs.writeTextDir "github_checks.py" (builtins.readFile ../scripts/github_checks.py);
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "repo-update";
      runtimeInputs = [
        pkgs.python3
        pkgs.git
        pkgs.gh
      ];
      text = ''
        export PYTHONPATH=${checks}
        exec python3 ${../scripts/repo-update.py} --projects-dir ${lib.escapeShellArg (builtins.dirOf machine.dotfilesDirectory)} "$@"
      '';
    })
  ];
}
