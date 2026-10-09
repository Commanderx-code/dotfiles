{ config, lib, ... }:

# Plasma settings owned by these dotfiles: the palette's colour scheme and the
# shared fixed-width font. Everything else in Plasma (panels, shortcuts, window
# decorations, Kvantum) keeps the settings made in System Settings; plasma-manager
# writes only the keys declared here (overrideConfig stays off).
let
  theme = config.commander.theme;
  c = theme.colors;
  t = theme.terminal;
  inherit (import ../lib/colors.nix { inherit lib; }) rgb;
  # "catppuccin-mocha" -> "CommanderCatppuccinMocha": the name plasma-apply-colorscheme takes.
  schemeName =
    "Commander"
    + lib.concatMapStrings (
      word: lib.toUpper (builtins.substring 0 1 word) + builtins.substring 1 (-1) word
    ) (lib.splitString "-" theme.id);

  group =
    background: alternate: foreground:
    lib.concatStrings (
      lib.mapAttrsToList (key: value: "${key}=${rgb value}\n") {
        BackgroundAlternate = alternate;
        BackgroundNormal = background;
        DecorationFocus = c.cyan;
        DecorationHover = c.purple;
        ForegroundActive = c.cyan;
        ForegroundInactive = c.muted;
        ForegroundLink = c.blue;
        ForegroundNegative = c.red;
        ForegroundNeutral = c.orange;
        ForegroundNormal = foreground;
        ForegroundPositive = c.green;
        ForegroundVisited = c.purple;
      }
    );

  colorScheme = ''
    [ColorEffects:Disabled]
    Color=${rgb c.mantle}
    ColorAmount=0
    ColorEffect=0
    ContrastAmount=0.65
    ContrastEffect=1
    IntensityAmount=0.1
    IntensityEffect=2

    [ColorEffects:Inactive]
    ChangeSelectionColor=true
    Color=${rgb c.mantle}
    ColorAmount=0.025
    ColorEffect=2
    ContrastAmount=0.1
    ContrastEffect=2
    Enable=false
    IntensityAmount=0
    IntensityEffect=0

    [Colors:Button]
    ${group c.surface c.overlay c.text}
    [Colors:Complementary]
    ${group c.mantle c.surface c.text}
    [Colors:Header]
    ${group c.mantle c.surface c.text}
    [Colors:Header][Inactive]
    ${group c.mantle c.surface c.subtext}
    [Colors:Selection]
    ${group t.selection t.selection t.selectionText}
    [Colors:Tooltip]
    ${group c.mantle c.surface c.text}
    [Colors:View]
    ${group c.mantle c.base c.text}
    [Colors:Window]
    ${group c.base c.surface c.text}
    [General]
    ColorScheme=${schemeName}
    Name=Commander (${theme.name})
    shadeSortColumn=true

    [KDE]
    contrast=4

    [WM]
    activeBackground=${rgb c.mantle}
    activeBlend=${rgb c.text}
    activeForeground=${rgb c.text}
    inactiveBackground=${rgb c.mantle}
    inactiveBlend=${rgb c.muted}
    inactiveForeground=${rgb c.muted}
  '';
in
{
  home.file.".local/share/color-schemes/${schemeName}.colors".text = colorScheme;

  programs.plasma = {
    enable = true;
    # Applied at the next login; `rice` also applies it straight away.
    workspace.colorScheme = schemeName;
    fonts.fixedWidth = {
      family = "JetBrainsMono Nerd Font Mono";
      pointSize = 10;
    };
  };
}
