{
  buildEnv,
  lib,
  makeDesktopItem,
  mkNixPak,
  qq,
  ...
}:
let
  appId = "com.qq.QQ";

  wrapped = mkNixPak {
    config =
      { sloth, ... }:
      {
        app = {
          package = qq;
          binPath = "bin/qq";
        };
        flatpak.appId = appId;

        imports = [
          ./modules/common.nix
          ./modules/gui-base.nix
          ./modules/network.nix
        ];

        bubblewrap = {
          bind.rw = [
            sloth.xdgDocumentsDir
            sloth.xdgDownloadDir
            sloth.xdgMusicDir
            sloth.xdgPicturesDir
            sloth.xdgVideosDir
          ];
          sockets = {
            pipewire = true;
            wayland = true;
            x11 = false;
          };
        };
      };
  };

  exePath = lib.getExe wrapped.config.script;
in
buildEnv {
  inherit (wrapped.config.script) name meta passthru;

  paths = [
    wrapped.config.script
    (makeDesktopItem {
      name = appId;
      desktopName = "QQ";
      genericName = "QQ Boxed";
      comment = "Tencent QQ desktop client in a nixpak sandbox.";
      exec = "${exePath} %U";
      terminal = false;
      icon = "${qq}/share/icons/hicolor/512x512/apps/qq.png";
      startupNotify = true;
      startupWMClass = "QQ";
      type = "Application";
      categories = [
        "InstantMessaging"
        "Network"
      ];
      extraConfig = {
        X-Flatpak = appId;
      };
    })
  ];
}
