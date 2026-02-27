{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe getExe';
  cfg = config.my.desktop.hyprland;
  hyprpicker' = getExe pkgs.hyprpicker;
  wl-copy' = getExe' pkgs.wl-clipboard-rs "wl-copy";
  notify-send' = getExe' pkgs.libnotify "notify-send";
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprpicker
      (writeShellScriptBin "hyprpicker-wl-copy" ''
        ${hyprpicker'} \
        | tee >(${wl-copy'}) \
        >(${notify-send'} "Color picked" "$(cat)") \
        >/dev/null
      '')
    ];
  };
}
