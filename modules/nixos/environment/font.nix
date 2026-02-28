{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.desktop;
  inherit (lib.modules) mkIf;
in {
  config = mkIf cfg.enable {
    # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
    fonts = {
      # use fonts specified by user rather than default ones
      enableDefaultPackages = false;
      fontDir = {
        enable = true;
        # this can allow us to save some storage space
        decompressFonts = true;
      };

      # user defined fonts
      # the reason there's Noto Color Emoji everywhere is to override DejaVu's
      # B&W emojis that would sometimes show instead of some Color emojis
      fontconfig.defaultFonts = {
        serif = ["Source Han Serif SC" "Source Han Serif TC" "Noto Color Emoji" "SFProDisplay Nerd Font"];
        sansSerif = ["Source Han Sans SC" "Source Han Sans TC" "Noto Color Emoji" "SFProDisplay Nerd Font"];
        monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
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
