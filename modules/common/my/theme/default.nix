{
  lib,
  config,
  ...
}: let
  inherit (lib.my) scanPaths relativeToConfig;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum str nullOr package path coercedTo attrs;
  inherit (config) my;
in {
  imports = scanPaths ./.;

  options.my.theme = {
    default = mkOption {
      type = nullOr (enum ["tokyonight" "catppuccin"]);
      default = "tokyonight";
      description = "The theme to use";
    };
    colorscheme = {
      slug = mkOption {
        type = nullOr str;
        default = null;
        description = "The slug of the colorscheme";
      };
      name = mkOption {
        type = nullOr str;
        default = null;
        description = "The name of the colorscheme";
      };
      author = mkOption {
        type = nullOr str;
        default = null;
        description = "The author of the colorscheme";
      };
      description = mkOption {
        type = nullOr str;
        default = null;
        description = "The description of the colorscheme";
      };
      palette = mkOption {
        type = nullOr attrs;
        default = null;
        description = "The palette of the colorscheme";
      };
    };
    avatar = mkOption {
      type = nullOr (coercedTo package toString path);
      default =
        if my.gui.enable
        then (relativeToConfig "avatars/makima.jpg")
        else null;
      description = "The avatar of the user";
    };
    wallpaper = mkOption {
      type = nullOr (coercedTo package toString path);
      default =
        if my.gui.enable
        then ./nix.png
        else null;
      description = "The wallpaper of the system";
    };
  };
}
