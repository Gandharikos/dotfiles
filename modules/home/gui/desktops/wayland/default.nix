{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) isWayland;
in {
  imports = lib.my.scanPaths ./.;

  config = mkIf (isWayland config) {
    home.packages = with pkgs; [
      grim
      slurp
      tesseract5
      # use more uwsm wrappers
      uwsm
      playerctl
      avizo
      wireplumber
      brillo
      brightnessctl
      wf-recorder
      wl-clip-persist
      wl-clipboard-rs
      wl-screenrec
      wlr-randr
      ffmpeg
      glib
      gnome-console
      gnome-photos
      gnome-tour
      gnome-connections
      gnome-font-viewer
      gnome-shell-extensions
      gnome-maps
      gnome-characters
    ];
  };
}
