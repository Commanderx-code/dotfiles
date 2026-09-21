{
  config,
  machine,
  pkgs,
  ...
}:

{
  # Zed itself is installed by the system package manager.
  # Rust, Nix, Markdown and Prettier tools are shared with nvim.nix.
  home.packages = with pkgs; [
    basedpyright
    ruff
    bash-language-server
    shellcheck
    shfmt
    tombi
    yaml-language-server
    vtsls
    vscode-langservers-extracted
  ];

  # Keep settings writable: Zed updates them when installing agents or extensions.
  # Credentials stay in the provider's credential store, never in these files.
  xdg.configFile = builtins.listToAttrs (
    map
      (name: {
        name = "zed/${name}.json";
        value.source = config.lib.file.mkOutOfStoreSymlink "${machine.dotfilesDirectory}/configs/zed/${name}.json";
      })
      [
        "settings"
        "keymap"
        "tasks"
      ]
  );
}
