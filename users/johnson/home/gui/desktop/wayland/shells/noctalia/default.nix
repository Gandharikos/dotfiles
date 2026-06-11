{
  inputs,
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;
  inherit (osConfig.dot.keyboard) keys;
  inherit (config.nixporn)
    avatar
    colorscheme
    palette
    wallpaper
    ;
  inherit (palette) ansi;

  enable = osConfig.dot.gui.desktop.wayland.enable && desktop.shell.default == "noctalia";
  wallpaperDirectory =
    if wallpaper == null then "~/Pictures/Wallpapers" else builtins.dirOf (toString wallpaper);
  baseSettings = import ./settings.nix {
    inherit
      config
      keys
      lib
      avatar
      wallpaper
      wallpaperDirectory
      ;
  };
  noctaliaPalette = {
    mPrimary = ansi.blue;
    mOnPrimary = ansi.bg;
    mSecondary = ansi.magenta;
    mOnSecondary = ansi.bg;
    mTertiary = ansi.cyan;
    mOnTertiary = ansi.bg;
    mError = ansi.red;
    mOnError = ansi.bg;
    mSurface = ansi.bg;
    mOnSurface = ansi.fg;
    mHover = ansi.cyan;
    mOnHover = ansi.bg;
    mSurfaceVariant = ansi.black;
    mOnSurfaceVariant = ansi.white;
    mOutline = ansi.bright_black;
    mShadow = ansi.black;
  };
  settings = lib.recursiveUpdate baseSettings {
    theme = {
      mode = config.nixporn.colorschemes.${colorscheme}.polarity;
      source = "custom";
      custom_palette = "nixporn";
    };
  };
in
{
  imports = [
    inputs.noctalia.homeModules.default
    ./bindings.nix
  ];

  config = mkIf enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      inherit settings;
      customPalettes.nixporn = {
        dark = noctaliaPalette;
        light = noctaliaPalette;
      };
    };

    home.packages = [
      pkgs.evtest
    ];
  };
}
