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
          --prefix PATH : ${pkgs.lib.escapeShellArg (pkgs.lib.makeBinPath runtime)}
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
    version = "0.32.3";
    url = "https://github.com/matthart1983/netwatch/releases/download/v0.32.3/netwatch-linux-x86_64.tar.gz";
    sha256 = "884314c9636d141d6b317069f161c7e7efd1050cac8d395db815e09bdfdd5313";
    unpack = ''tar -xOf "$src" netwatch-linux-x86_64 > "$out/libexec/netwatch"'';
  };
  tfm = binary {
    name = "tfm";
    helpText = "terminal file manager";
    version = "0.1.0-beta.0";
    url = "https://github.com/clarkarch/tfm-tui/releases/download/v0.1.0-beta.0/tfm-x86_64-linux.gz";
    sha256 = "46e48344b23affa7e6dc8332b19c857a2012dc5de5eacda895cb7a9cb550eb9f";
    unpack = ''gzip -dc "$src" > "$out/libexec/tfm"'';
    runtime = [
      pkgs.xdg-utils
      pkgs.librsvg
      pkgs.imagemagick
      pkgs.ffmpeg
      pkgs.wl-clipboard
    ];
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
