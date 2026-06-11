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
  inherit (lib.attrsets) optionalAttrs;
  inherit (config.my.gui) desktop;
  inherit (config.nixporn) avatar wallpaper;

  enable = osConfig.dot.gui.desktop.wayland.enable && desktop.shell.default == "dank-material-shell";
  dmsSettingsFile = lib.dot.relativeToConfig "dank-material-shell/settings.json";
  settings = builtins.fromJSON (builtins.readFile dmsSettingsFile);

  dmsSessionFile = lib.dot.relativeToConfig "dank-material-shell/session.json";
  sessionSettings = builtins.fromJSON (builtins.readFile dmsSessionFile);
  plugins = import ./plugins.nix { inherit pkgs; };
in
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    ./bindings.nix
  ];

  config = mkIf enable {
    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableVPN = true; # VPN management widget
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = false; # Calendar integration (khal)
      session =
        sessionSettings
        // optionalAttrs (wallpaper != null) {
          wallpaperPath = toString wallpaper;
          wallpaperPathLight = toString wallpaper;
          wallpaperPathDark = toString wallpaper;
        };
      inherit settings plugins;
    };

    home.file = optionalAttrs (avatar != null) {
      ".face".source = avatar;
    };
    programs.lazyvim.extraPlugins = [
      pkgs.vimPlugins.base16-nvim
    ];
  };
}
