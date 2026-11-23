{ pkgs }:
let
  binary =
    {
      name,
      version,
      url,
      sha256,
      unpack,
      helpText,
      runtime ? [ ],
      wrapperArgs ? [ ],
    }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = name;
      inherit version;
      src = pkgs.fetchurl { inherit url sha256; };
      dontUnpack = true;
      # Bun-compiled TFM stores its application after the ELF sections.
      dontStrip = true;
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.makeWrapper
      ];
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/libexec" "$out/bin"
        ${unpack}
        chmod 755 "$out/libexec/${name}"
        makeWrapper "$out/libexec/${name}" "$out/bin/${name}" \
          --prefix PATH : ${pkgs.lib.escapeShellArg (pkgs.lib.makeBinPath runtime)} \
          ${pkgs.lib.escapeShellArgs wrapperArgs}
        runHook postInstall
      '';
      # Exercise the final binary after stripping/ELF fixups, not just the download.
      doInstallCheck = true;
      installCheckPhase = ''
        runHook preInstallCheck
        XDG_CONFIG_HOME="$TMPDIR/smoke-config" "$out/bin/${name}" --help > "$TMPDIR/help.txt" 2>&1
        grep -F -- ${pkgs.lib.escapeShellArg helpText} "$TMPDIR/help.txt"
        runHook postInstallCheck
      '';
      meta = {
        platforms = [ "x86_64-linux" ];
        mainProgram = name;
        sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
      };
    };
in
{
  netwatch = binary {
    name = "netwatch";
    helpText = "netwatch";
    version = "1.0.0";
    url = "https://github.com/matthart1983/netwatch/releases/download/v1.0.0/netwatch-linux-x86_64.tar.gz";
    sha256 = "f1d59921344608a072aeaff9c35ec5a3757905cc4b506d25e44c3e1253a2b808";
    unpack = ''tar -xOf "$src" netwatch-linux-x86_64 > "$out/libexec/netwatch"'';
  };
  tfm = binary {
    name = "tfm";
    helpText = "terminal file manager";
    version = "1.2.0";
    url = "https://github.com/clarkarch/tfm-tui/releases/download/v1.2.0/tfm-x86_64-linux.gz";
    sha256 = "5b3db69950a1a12addd14fc3c310fe29805ad0b0295fdf2d484004c518bc4d9f";
    unpack = ''gzip -dc "$src" > "$out/libexec/tfm"'';
    runtime = [
      pkgs.xdg-utils
      pkgs.librsvg
      pkgs.imagemagick
      pkgs.ffmpeg
      pkgs.wl-clipboard
    ];
    # TFM looks for video previews' ffmpeg only in TFM_FFMPEG or beside its own
    # binary, never on PATH, so point it at the Nix one.
    wrapperArgs = [
      "--set-default"
      "TFM_FFMPEG"
      "${pkgs.ffmpeg}/bin/ffmpeg"
    ];
  };
  # The standalone kitten from the kitty releases: fzf-preview draws image
  # previews with `kitten icat` in Ghostty, which has no Sixel support.
  kitten = binary {
    name = "kitten";
    helpText = "kitten serves as a launcher";
    version = "0.51.1";
    url = "https://github.com/kovidgoyal/kitty/releases/download/v0.51.1/kitten-linux-amd64";
    sha256 = "086a767464c1cbbbe93ed0fcd656047d9771fb6b79d30cd00f5a81f8d2525d1d";
    unpack = ''cp "$src" "$out/libexec/kitten"'';
  };
  # This is OreoMuncher45's Spotify TUI, not the unrelated pkgs.cassette app.
  cassette = binary {
    name = "cassette";
    helpText = "print build metadata";
    version = "1.0.0";
    url = "https://github.com/OreoMuncher45/cassette/releases/download/v1.0.0/cassette-linux-amd64.tar.gz";
    sha256 = "cda53038e57cc7cbdf7b2124b0eecde2429512fa00847fbc4f978a4e67068bae";
    unpack = ''tar -xOf "$src" cassette > "$out/libexec/cassette"'';
    runtime = [
      pkgs.librespot
      pkgs.xdg-utils
    ];
  };
}
