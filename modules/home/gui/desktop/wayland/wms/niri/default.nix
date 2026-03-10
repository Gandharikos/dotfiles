{
  inputs,
  lib,
  config,
  ...
}: let
  inherit (lib.my) scanPaths isWayland;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;
  cfg = desktop.niri;
in {
  imports = [inputs.niri.homeModules.niri] ++ scanPaths ./.;
  options.my.gui.desktop.niri = {
    enable =
      mkEnableOption "Enable Niri"
      // {
        default = isWayland config && desktop.default == "niri";
        internal = true;
        readOnly = true;
      };
  };
  config = mkIf cfg.enable {
    my.gui.desktop.shot = "dms";
    programs.niri = {
      enable = true;
      settings = {
        prefer-no-csd = true;
        hotkey-overlay.skip-at-startup = true;
      };
    };
  };
}
