{
  lib,
  pkgs,
  sloth,
  ...
}:
let
  envSuffix = envKey: suffix: sloth.concat' (sloth.env envKey) suffix;
  cursorTheme = pkgs.bibata-cursors;
  iconTheme = pkgs.papirus-icon-theme;
in
{
  config = {
    gpu = {
      enable = lib.mkDefault true;
      provider = "nixos";
      bundlePackage = pkgs.mesa.drivers;
    };

    fonts.enable = false;
    locale.enable = true;

    bubblewrap = {
      network = lib.mkDefault false;
      bind.rw = [
        (envSuffix "XDG_RUNTIME_DIR" "/pulse")
        (sloth.concat [
          (sloth.env "XDG_RUNTIME_DIR")
          "/"
          (sloth.envOr "WAYLAND_DISPLAY" "wayland-0")
        ])
      ];
      bind.ro = [
        (sloth.concat' sloth.xdgConfigHome "/fontconfig")
        (sloth.concat' sloth.xdgConfigHome "/gtk-2.0")
        (sloth.concat' sloth.xdgConfigHome "/gtk-3.0")
        (sloth.concat' sloth.xdgConfigHome "/gtk-4.0")
        "/etc/fonts"
        "/etc/localtime"
        "/etc/static/egl"
        "/etc/zoneinfo"
      ];
      bind.dev = [
        "/dev/dri"
        "/dev/shm"
      ];
      tmpfs = [ "/tmp" ];
      env = {
        XCURSOR_PATH = lib.mkForce (
          lib.concatStringsSep ":" [
            "${cursorTheme}/share/icons"
            "${cursorTheme}/share/pixmaps"
          ]
        );
        XDG_DATA_DIRS = lib.mkForce (
          lib.makeSearchPath "share" [
            cursorTheme
            iconTheme
            pkgs.shared-mime-info
          ]
        );
      };
    };
  };
}
