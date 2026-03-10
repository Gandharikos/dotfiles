{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.my) isWayland;
  enable = isWayland config && config.my.gui.desktop.default == "niri";
  niriPkg = config.programs.niri.package or pkgs.niri;
  niriSession = getExe' niriPkg "niri-session";
in {
  config = mkIf enable {
    programs.niri.enable = true;
    services.displayManager.defaultSession = "niri";

    # Ensure login uses niri-session so env vars and portals are set up correctly.
    my.gui.desktop.exec = niriSession;
  };
}
