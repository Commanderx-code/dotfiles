{ ... }:

{
  imports = [
    ./zellij.nix
    ./terminal-trials.nix
  ];

  # The Ghostty theme, topbar.css and Konsole's Commander colours come from modules/theme.nix.
  xdg.configFile."ghostty/spotatui.conf".source = ../../configs/ghostty/spotatui.conf;

  # Ghostty's packaged user service is Type=notify-reload with ReloadSignal=SIGUSR2.
  # systemd 262 refuses to start such a service unless the process already handles
  # that signal when it reports ready, and Ghostty sometimes installs its handler
  # just after ("lacks handler for reload signal USR2, refusing service startup"),
  # so launching it failed now and then. As a plain notify service it always
  # starts, and reloading still sends the same signal.
  xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service.d/startup.conf" = {
    text = ''
      [Service]
      Type=notify
      ExecReload=/usr/bin/kill -USR2 $MAINPID
    '';
    onChange = "/usr/bin/systemctl --user daemon-reload || true";
  };

  # fzf preview helper used by Fish/fzf.
  home.file.".local/bin/fzf-preview" = {
    source = ../../configs/scripts/fzf-preview;
    executable = true;
  };

  home.file.".local/bin/fzf-rg-results" = {
    source = ../../configs/scripts/fzf-rg-results;
    executable = true;
  };

  home.file.".local/bin/clickpaste" = {
    source = ../scripts/clickpaste.py;
    executable = true;
  };

  # Konsole global configuration.
  xdg.configFile."konsolerc".source = ../../configs/konsole/konsolerc;

  # Konsole profile; Sweet stays available as an alternative scheme.
  home.file.".local/share/konsole/Garuda.profile".source = ../../configs/konsole/Garuda.profile;

  home.file.".local/share/konsole/Sweet.colorscheme".source = ../../configs/konsole/Sweet.colorscheme;
}
