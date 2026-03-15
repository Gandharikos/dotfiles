{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;
  cfg = desktop.cosmic;
in {
  options.my.gui.desktop.cosmic = {
    enable =
      mkEnableOption "Enable Hyprland"
      // {
        default = desktop.wayland.enable && desktop.default == "cosmic";
        internal = true;
        readOnly = true;
      };
  };

  config = mkIf cfg.enable {
    services.desktopManager.cosmic.enable = true;

    environment.cosmic.excludePackages = [
      pkgs.cosmic-edit
      pkgs.cosmic-term
      pkgs.cosmic-store
    ];

    my.gui.login = "cosmic-greeter";
  };
}
