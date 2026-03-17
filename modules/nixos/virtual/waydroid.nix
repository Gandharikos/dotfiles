{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.meta) getExe;
  weston' = getExe pkgs.weston;
  waydroid' = getExe pkgs.waydroid;

  cfg = config.my.virtual.waydroid;

  waydroid-ui = pkgs.writeShellScriptBin "waydroid-ui" ''
    export WAYLAND_DISPLAY=wayland-0
    ${weston'} -Swayland-1 --width=600 --height=1000 --shell="kiosk-shell.so" &
    WESTON_PID=$!

    export WAYLAND_DISPLAY=wayland-1
    ${waydroid'} show-full-ui &

    wait $WESTON_PID
    ${waydroid'} session stop
  '';
in
{
  options.my.virtual.waydroid = {
    enable = mkEnableOption "Enable waydroid" // {
      default = config.my.virtual.enable;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      waydroid
      waydroid-ui
    ];

    virtualisation = {
      waydroid.enable = true;
    };
  };
}
