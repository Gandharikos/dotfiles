{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
in
{
  imports = lib.my.scanPaths ./.;

  config = mkIf config.my.gui.desktop.wayland.enable {
    home.packages = with pkgs; [
      # keep-sorted start
      avizo
      brightnessctl
      brillo
      ffmpeg
      gifski # GIF encoder
      glib
      gnome-characters
      gnome-connections
      gnome-console
      gnome-font-viewer
      gnome-maps
      gnome-photos
      gnome-shell-extensions
      gnome-tour
      gpu-screen-recorder # GPU-accelerated screen recorder
      grim
      imagemagick # Image manipulation
      playerctl
      slurp
      tesseract5
      translate-shell # Translation tool
      # use more uwsm wrappers
      uwsm
      wf-recorder
      wireplumber
      wl-clip-persist
      wl-clipboard-rs
      wlr-randr
      zbar # Barcode/QR code reader
      # keep-sorted end
    ];
  };
}
