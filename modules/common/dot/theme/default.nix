{
  lib,
  config,
  ...
}:
let
  inherit (lib.dot) scanPaths relativeToConfig;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    enum
    str
    nullOr
    package
    path
    coercedTo
    attrs
    ;
  inherit (config) dot;
in
{
  imports = scanPaths ./.;

  options.dot.theme = {
    default = mkOption {
      type = nullOr (enum [
        "tokyonight"
        "catppuccin"
      ]);
      inherit (dot.admin.theme) default;
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
        if dot.admin.theme.avatar != null then
          dot.admin.theme.avatar
        else if dot.gui.enable then
          (relativeToConfig "avatars/makima.jpg")
        else
          null;
      description = "The avatar of the user";
    };
    wallpaper = mkOption {
      type = nullOr (coercedTo package toString path);
      default =
        if dot.admin.theme.wallpaper != null then
          dot.admin.theme.wallpaper
        else if dot.gui.enable then
          ./nix.png
        else
          null;
      description = "The wallpaper of the system";
    };
  };
}
