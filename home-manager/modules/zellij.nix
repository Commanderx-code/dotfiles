{
  config,
  pkgs,
  lib,
  ...
}:
let
  c = config.commander.theme.colors;
  ansi = config.commander.theme.terminal.ansi;
  # Release hashes from each upstream's GitHub asset metadata / SHA256SUMS.
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.24.0/zjstatus.wasm";
    sha256 = "1ccedece1ded62cf3e209be690cdd39ca6fb9e8228ed71a951f6507f9956669b";
  };
  harpoon = pkgs.fetchurl {
    url = "https://github.com/Nacho114/harpoon/releases/download/v0.3.0/harpoon.wasm";
    sha256 = "7f8cf57a71f1dbbbd115337a31638780d7e18e9b876def1c81c970188caa32f2";
  };
  zesh = pkgs.stdenvNoCC.mkDerivation {
    pname = "zesh";
    version = "0.3.0";
    src = pkgs.fetchurl {
      url = "https://github.com/roberte777/zesh/releases/download/zesh-v0.3.0/zesh";
      sha256 = "2d4112a54938171c0adc47296505c3c306d014e10b964dd1f5776d767a5e4e1f";
    };
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    installPhase = ''
      install -Dm755 "$src" "$out/bin/zesh"
    '';
    meta = {
      description = "Zellij session helper with zoxide integration";
      homepage = "https://github.com/roberte777/zesh";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };
  # Keep the custom session/tab bar above Zellij's built-in shortcut hints.
  tabTemplate = ''
    default_tab_template {
      children
      pane size=1 borderless=true {
        plugin location="file:${zjstatus}" {
          format_left "{mode} #[fg=${c.cyan},bold]{session}  {tabs}"
          format_right "#[fg=${c.subtext}] Ctrl+G lock/unlock "
          format_space "#[bg=${c.mantle}]"
          hide_frame_for_single_pane "false"
          mode_normal "#[fg=${c.mantle},bg=${c.purple},bold] CONTROL #[fg=${c.purple},bg=${c.mantle}]"
          mode_locked "#[fg=${c.mantle},bg=${c.green},bold] LOCKED #[fg=${c.green},bg=${c.mantle}]"
          mode_default_to_mode "normal"
          tab_normal "#[fg=${c.subtext},bg=${c.mantle}] {index} {name} "
          tab_active "#[fg=${c.mantle},bg=${c.cyan},bold] {index} {name} #[fg=${c.cyan},bg=${c.mantle}]"
        }
      }
      pane size=1 borderless=true {
        plugin location="zellij:status-bar"
      }
    }
  '';
in
{
  home.packages = [ zesh ];
  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
    enableBashIntegration = false;
    enableZshIntegration = false;
    settings = {
      theme = "commander";
      default_shell = "${pkgs.fish}/bin/fish";
      default_mode = "locked";
      default_layout = "commander";
    };
    extraConfig = ''
      // The palette chosen with `rice` (modules/theme.nix).
      themes {
        commander {
          fg "${c.text}"
          bg "${c.surface}"
          black "${c.mantle}"
          red "${c.red}"
          green "${c.green}"
          yellow "${c.yellow}"
          blue "${c.blue}"
          magenta "${c.purple}"
          cyan "${c.cyan}"
          white "${builtins.elemAt ansi 7}"
          orange "${c.orange}"
        }
      }
      keybinds {
        shared_except "locked" {
          bind "Alt y" {
            LaunchOrFocusPlugin "file:${harpoon}" {
              floating true
              move_to_focused_tab true
            }
          }
        }
      }
    '';
  };
  xdg.configFile."zellij/layouts/commander.kdl".text = ''
    layout {
      ${tabTemplate}
      tab name="Shell" {
        pane
      }
    }
  '';
  xdg.configFile."zellij/layouts/commander-dev.kdl".text = ''
    layout {
      ${tabTemplate}
      tab name="Dev" {
        pane split_direction="vertical" {
          pane size="65%" name="Editor" command="${pkgs.neovim}/bin/nvim" focus=true
          pane {
            pane name="Fish"
            pane name="Git" command="${pkgs.lazygit}/bin/lazygit" start_suspended=true
          }
        }
      }
    }
  '';
}
