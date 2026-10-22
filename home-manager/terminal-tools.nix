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
    version = "0.35.4";
    url = "https://github.com/matthart1983/netwatch/releases/download/v0.35.4/netwatch-linux-x86_64.tar.gz";
    sha256 = "183272223a09c93fc890f6d5c9b9f71fb4d8883292d94963e10b5fabf1a7a1bd";
    unpack = ''tar -xOf "$src" netwatch-linux-x86_64 > "$out/libexec/netwatch"'';
  };
  tfm = binary {
    name = "tfm";
    helpText = "terminal file manager";
    version = "1.1.0";
    url = "https://github.com/clarkarch/tfm-tui/releases/download/v1.1.0/tfm-x86_64-linux.gz";
    sha256 = "b3d9a7cf8855501d79cbef230eedc730ec8a84acaaa8cf5b33be5cd9282c6d0e";
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
    version = "0.49.2";
    url = "https://github.com/kovidgoyal/kitty/releases/download/v0.49.2/kitten-linux-amd64";
    sha256 = "2a803b4d411f327cc41b7193cb529f6de06ae3b169a346b3060212bbfeafc8bc";
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
