{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.dot) gui;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf gui.enable {
    # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
    fonts = {
      # use fonts specified by user rather than default ones
      enableDefaultPackages = false;
      fontDir = {
        enable = true;
        # this can allow us to save some storage space
        decompressFonts = true;
      };
    };

    # https://wiki.archlinux.org/title/KMSCON
    services.kmscon = {
      # Use kmscon as the virtual console instead of gettys.
      # kmscon is a kms/dri-based userspace virtual terminal implementation.
      # It supports a richer feature set than the standard linux console VT,
      # including full unicode support, and when the video card supports drm should be much faster.
      enable = true;
      fonts = [
        {
          name = "Source Code Pro";
          package = pkgs.source-code-pro;
        }
      ];
      extraOptions = "--term xterm-256color";
      extraConfig = "font-size=12";
      # Whether to use 3D hardware acceleration to render the console.
      hwRender = true;
    };
  };
}
