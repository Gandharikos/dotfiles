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
    wallpaper
    ;

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
      settings = baseSettings;
    };

    home.packages = [
      pkgs.evtest
    ];
  };
}
