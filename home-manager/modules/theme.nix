{
  config,
  lib,
  pkgs,
  ...
}:

# One palette for the workstation. `rice <name>` writes the choice to
# home-manager/rice.json; every colour below comes from configs/themes/<name>.json.
let
  themesDirectory = ../../configs/themes;
  selection = builtins.fromJSON (builtins.readFile ../rice.json);
  themeFile = themesDirectory + "/${selection.theme}.json";
  theme =
    if builtins.pathExists themeFile then
      builtins.fromJSON (builtins.readFile themeFile) // { id = selection.theme; }
    else
      throw "home-manager/rice.json names theme '${selection.theme}', but configs/themes/${selection.theme}.json does not exist";
  c = theme.colors;
  t = theme.terminal;
  inherit (import ../lib/colors.nix { inherit lib; }) rgb;

  ghosttyTheme = ''
    # Generated from configs/themes/${theme.id}.json by modules/theme.nix.
    ${
      lib.concatImapStrings (i: color: "palette = ${toString (i - 1)}=${color}\n") t.ansi
    }background = ${c.base}
    foreground = ${c.text}
    cursor-color = ${t.cursor}
    cursor-text = ${t.cursorText}
    selection-background = ${t.selection}
    selection-foreground = ${t.selectionText}
  '';

  konsoleSection = name: color: ''
    [${name}]
    Color=${rgb color}

  '';
  # Konsole's Intense variants are the bright half of the ANSI palette.
  konsoleColor =
    name: normal: intense:
    konsoleSection name normal
    + konsoleSection "${name}Faint" normal
    + konsoleSection "${name}Intense" intense;
  konsoleScheme = ''
    ${konsoleColor "Background" c.base c.base}${konsoleColor "Foreground" c.text c.text}${
      lib.concatMapStrings (
        i: konsoleColor "Color${toString i}" (builtins.elemAt t.ansi i) (builtins.elemAt t.ansi (i + 8))
      ) (lib.range 0 7)
    }[General]
    Blur=true
    ColorRandomization=false
    Description=Commander (${theme.name})
    Opacity=0.94
    Wallpaper=
  '';

  fzfColors = lib.concatStringsSep "," [
    "fg:${c.subtext}"
    "bg:-1"
    "hl:${c.cyan}"
    "fg+:${c.text}"
    "bg+:${c.surface}"
    "hl+:${c.cyan}"
    "info:${c.purple}"
    "prompt:${c.green}"
    "pointer:${c.pink}"
    "marker:${c.green}"
    "spinner:${c.pink}"
    "header:${c.muted}"
    "border:${c.overlay}"
    "label:${c.subtext}"
    "query:${c.text}"
    "gutter:-1"
  ];

  btopTheme = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (key: value: ''theme[${key}]="${value}"'') {
      main_bg = c.base;
      main_fg = c.text;
      title = c.text;
      hi_fg = c.cyan;
      selected_bg = c.surface;
      selected_fg = c.cyan;
      inactive_fg = c.muted;
      graph_text = c.subtext;
      meter_bg = c.overlay;
      proc_misc = c.purple;
      cpu_box = c.purple;
      mem_box = c.green;
      net_box = c.pink;
      proc_box = c.cyan;
      div_line = c.overlay;
      temp_start = c.green;
      temp_mid = c.yellow;
      temp_end = c.red;
      cpu_start = c.cyan;
      cpu_mid = c.purple;
      cpu_end = c.pink;
      free_start = c.green;
      free_mid = c.green;
      free_end = c.cyan;
      cached_start = c.blue;
      cached_mid = c.blue;
      cached_end = c.purple;
      available_start = c.yellow;
      available_mid = c.orange;
      available_end = c.orange;
      used_start = c.pink;
      used_mid = c.red;
      used_end = c.red;
      download_start = c.cyan;
      download_mid = c.blue;
      download_end = c.purple;
      upload_start = c.green;
      upload_mid = c.yellow;
      upload_end = c.orange;
      process_start = c.cyan;
      process_mid = c.purple;
      process_end = c.pink;
    }
  );

  fg = color: { foreground = color; };
  bold = color: {
    foreground = color;
    is_bold = true;
  };
  ezaTheme = {
    colourful = true;
    filekinds = {
      normal = fg c.text;
      directory = bold c.cyan;
      symlink = fg c.purple;
      pipe = fg c.yellow;
      block_device = bold c.yellow;
      char_device = bold c.yellow;
      socket = bold c.pink;
      special = fg c.yellow;
      executable = bold c.green;
      mount_point = bold c.blue;
    };
    perms = {
      user_read = fg c.yellow;
      user_write = fg c.red;
      user_execute_file = bold c.green;
      user_execute_other = fg c.green;
      group_read = fg c.yellow;
      group_write = fg c.red;
      group_execute = fg c.green;
      other_read = fg c.subtext;
      other_write = fg c.red;
      other_execute = fg c.green;
      special_user_file = fg c.purple;
      special_other = fg c.purple;
      attribute = fg c.muted;
    };
    size = {
      major = fg c.cyan;
      minor = fg c.muted;
      number_byte = fg c.subtext;
      number_kilo = fg c.subtext;
      number_mega = fg c.cyan;
      number_giga = fg c.purple;
      number_huge = fg c.pink;
      unit_byte = fg c.muted;
      unit_kilo = fg c.muted;
      unit_mega = fg c.cyan;
      unit_giga = fg c.purple;
      unit_huge = fg c.pink;
    };
    users = {
      user_you = fg c.yellow;
      user_root = fg c.red;
      user_other = fg c.subtext;
      group_yours = fg c.yellow;
      group_other = fg c.subtext;
      group_root = fg c.red;
    };
    links = {
      normal = fg c.cyan;
      multi_link_file = fg c.pink;
    };
    git = {
      new = fg c.green;
      modified = fg c.yellow;
      deleted = fg c.red;
      renamed = fg c.cyan;
      typechange = fg c.purple;
      ignored = fg c.muted;
      conflicted = fg c.red;
    };
    git_repo = {
      branch_main = fg c.green;
      branch_other = fg c.yellow;
      git_clean = fg c.green;
      git_dirty = fg c.red;
    };
    file_type = {
      image = fg c.purple;
      video = fg c.pink;
      music = fg c.pink;
      lossless = fg c.pink;
      crypto = fg c.green;
      document = fg c.subtext;
      compressed = fg c.red;
      temp = fg c.muted;
      compiled = fg c.orange;
      build = fg c.yellow;
      source = fg c.text;
    };
    punctuation = fg c.overlay;
    date = fg c.blue;
    inode = fg c.muted;
    blocks = fg c.muted;
    header = bold c.text;
    octal = fg c.purple;
    flags = fg c.purple;
    symlink_path = fg c.purple;
    control_char = fg c.red;
    broken_symlink = fg c.red;
    broken_path_overlay = fg c.red;
  };

  lazygitTheme = {
    gui.theme = {
      activeBorderColor = [
        c.cyan
        "bold"
      ];
      inactiveBorderColor = [ c.overlay ];
      searchingActiveBorderColor = [
        c.yellow
        "bold"
      ];
      optionsTextColor = [ c.blue ];
      selectedLineBgColor = [ c.surface ];
      inactiveViewSelectedLineBgColor = [ c.mantle ];
      cherryPickedCommitFgColor = [ c.base ];
      cherryPickedCommitBgColor = [ c.purple ];
      markedBaseCommitFgColor = [ c.base ];
      markedBaseCommitBgColor = [ c.yellow ];
      unstagedChangesColor = [ c.red ];
      defaultFgColor = [ c.text ];
    };
  };
  yaml = pkgs.formats.yaml { };
  btopThemeLine = pkgs.writeShellScript "btop-theme-line" ''
    set -eu
    conf=$1
    line='color_theme = "commander"'
    [ -L "$conf" ] && exit 0
    if [ -f "$conf" ]; then
      if ${pkgs.gnugrep}/bin/grep -q '^color_theme' "$conf"; then
        ${pkgs.gnused}/bin/sed -i "s|^color_theme *=.*|$line|" "$conf"
      else
        printf '%s\n' "$line" >> "$conf"
      fi
    else
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$conf")"
      printf '%s\n' "$line" > "$conf"
    fi
  '';
in
{
  options.commander.theme = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = "The palette chosen in home-manager/rice.json, read from configs/themes.";
  };

  config = {
    commander.theme = theme;

    # Ghostty: the live config is a writable copy; its `theme = commander` line reads this.
    xdg.configFile."ghostty/themes/commander".text = ghosttyTheme;
    xdg.configFile."ghostty/topbar.css".text = ''
      /* Generated from configs/themes/${theme.id}.json: opaque tab/title bar; the terminal keeps its transparency. */
      headerbar,
      toolbarview > .top-bar {
          background-color: ${c.mantle};
          background-image: none;
      }
    '';

    home.file.".local/share/konsole/Commander.colorscheme".text = konsoleScheme;

    # Neovim reads its colorscheme from here (see lua/plugins/colorscheme.lua).
    # An "nvim" entry in rice.json overrides the palette's choice and survives palette switches.
    xdg.configFile."nvim/lua/config/rice.lua".text = ''
      -- Generated from configs/themes/${theme.id}.json by modules/theme.nix.
      return { colorscheme = "${selection.nvim or theme.apps.nvim}" }
    '';

    xdg.configFile."eza/theme.yml".source = yaml.generate "eza-theme.yml" ezaTheme;
    xdg.configFile."lazygit/theme.yml".source = yaml.generate "lazygit-theme.yml" lazygitTheme;
    xdg.configFile."btop/themes/commander.theme".text = btopTheme + "\n";

    # Shell side: fzf colours, the bat theme, and lazygit's theme layered over its own config.
    # Sourced after conf.d/fzf.fish, which sets the rest of FZF_DEFAULT_OPTS.
    xdg.configFile."fish/conf.d/rice.fish".text = ''
      # Generated from configs/themes/${theme.id}.json by modules/theme.nix.
      set -gx COMMANDER_THEME ${theme.id}
      set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS --color=${fzfColors}"
      set -gx BAT_THEME ${lib.escapeShellArg theme.apps.bat}
      # lazygit creates config.yml itself on first run; the theme rides on top of it.
      set -l lazygit_config "$HOME/.config/lazygit"
      set -q XDG_CONFIG_HOME; and set lazygit_config "$XDG_CONFIG_HOME/lazygit"
      if test -f "$lazygit_config/config.yml"
          set -gx LG_CONFIG_FILE "$lazygit_config/config.yml,$lazygit_config/theme.yml"
      else
          set -gx LG_CONFIG_FILE "$lazygit_config/theme.yml"
      end
    '';

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
        syntax-theme = theme.apps.bat;
        plus-style = "syntax ${theme.diff.added}";
        minus-style = "syntax ${theme.diff.removed}";
        plus-emph-style = "syntax ${theme.diff.addedEmphasis}";
        minus-emph-style = "syntax ${theme.diff.removedEmphasis}";
        file-style = "${c.purple} bold";
        file-decoration-style = "${c.overlay} ul";
        hunk-header-style = "file line-number syntax";
        hunk-header-decoration-style = "${c.overlay} box";
        line-numbers-minus-style = c.red;
        line-numbers-plus-style = c.green;
        line-numbers-zero-style = c.muted;
        line-numbers-left-style = c.overlay;
        line-numbers-right-style = c.overlay;
      };
    };

    # btop rewrites btop.conf on exit, so it stays writable: only its theme line is set here.
    home.activation.btopTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${btopThemeLine} ${lib.escapeShellArg "${config.xdg.configHome}/btop/btop.conf"}
    '';
  };
}
