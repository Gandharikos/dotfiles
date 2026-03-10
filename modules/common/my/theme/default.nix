{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.my) scanPaths relativeToConfig;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum str nullOr package path coercedTo attrs;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
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
    # TODO: wallpaper engine support?
    avatar = mkOption {
      type = nullOr (coercedTo package toString path);
      default =
        if my.gui.enable
        then (relativeToConfig "avatars/pain.png")
        else null;
      description = "The avatar of the user";
    };
    wallpaper = mkOption {
      type = nullOr (coercedTo package toString path);
      # we don't set wallpaper on macos, because it doesn't work
      default =
        if isDarwin
        then null
        else if my.gui.enable
        then ./nix.png
        # pkgs.fetchurl {
        #   url = "https://github.com/huwqchn/wallpapers/blob/main/unorganized/nix.png";
        #   sha256 = "11qgd9k79fhpsk7x0q3cwin8i1ycf9kcd6c3si7sdck78rdhdwl8";
        # }
        else null;
      description = "The wallpaper of the system";
    };
  };
}
