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
      # keep-sorted start
      avizo
      brightnessctl
      brillo
      ffmpeg
      glib
      gnome-characters
      gnome-connections
      gnome-console
      gnome-font-viewer
      gnome-maps
      gnome-photos
      gnome-shell-extensions
      gnome-tour
      grim
      playerctl
      slurp
      tesseract5
      # use more uwsm wrappers
      uwsm
      wf-recorder
      wireplumber
      wl-clip-persist
      wl-clipboard-rs
      wl-screenrec
      wlr-randr
      # keep-sorted end
    ];
  };
}
