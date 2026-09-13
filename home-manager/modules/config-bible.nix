{ config, ... }:

let
  home = config.home.homeDirectory;
  bible = "${home}/github/projects/config-bible";
in
{
  xdg.enable = true;

  home.file.".local/bin/commander-config-bible" = {
    executable = true;
    text = ''
      #!/usr/bin/env sh

      app="${bible}/app/src-tauri/target/release/commander-config-bible"

      if [ ! -x "$app" ]; then
        echo "Commander Config Bible has not been built yet."
        echo
        echo "Run:"
        echo "  bible-app build"
        exit 1
      fi

      exec "$app"
    '';
  };

  # KDE / XDG application-menu entry.
  xdg.desktopEntries."commander-config-bible" = {
    name = "Commander Config Bible";
    genericName = "Configuration Documentation";
    comment = "Searchable documentation and recovery guide";

    exec = "${home}/.local/bin/commander-config-bible";
    icon = "${bible}/app/src-tauri/icons/icon.png";

    terminal = false;

    categories = [
      "Utility"
      "Documentation"
    ];

    startupNotify = true;
  };
}
