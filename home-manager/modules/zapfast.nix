{
  config,
  zapfast,
  nixgl,
  ...
}:

{
  # ZapFast is an OpenGL GUI. Outside NixOS it cannot see the host's Mesa
  # drivers, so run it through nixGL's Mesa wrapper (Intel iGPU drives the display).
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
  };

  home.packages = [ (config.lib.nixGL.wrap zapfast) ];
}
