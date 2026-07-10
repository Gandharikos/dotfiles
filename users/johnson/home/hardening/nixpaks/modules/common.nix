{
  config,
  lib,
  sloth,
  ...
}:
let
  inherit (config.flatpak) appId;
in
{
  config = {
    dbus = {
      policies = {
        "${appId}" = "own";
        "${appId}.*" = "own";
        "ca.desrt.dconf" = "talk";
        "org.a11y.Bus" = "see";
        "org.freedesktop.DBus" = "talk";
        "org.freedesktop.Notifications" = "talk";
        "org.freedesktop.portal.Desktop" = "talk";
        "org.freedesktop.portal.Documents" = "talk";
        "org.freedesktop.portal.FileChooser" = "talk";
        "org.freedesktop.portal.Fcitx" = "talk";
        "org.freedesktop.portal.IBus" = "talk";
        "org.freedesktop.portal.OpenURI" = "talk";
        "org.kde.StatusNotifierWatcher" = "talk";
      }
      // builtins.listToAttrs (
        map (id: lib.nameValuePair "org.kde.StatusNotifierItem-${toString id}-1" "own") (
          lib.lists.range 2 29
        )
      );
      args = [
        "--filter"
        "--sloppy-names"
      ];
    };

    bubblewrap.bind.rw = with sloth; [
      [
        (mkdir appDataDir)
        xdgDataHome
      ]
      [
        (mkdir appConfigDir)
        xdgConfigHome
      ]
      [
        (mkdir appCacheDir)
        xdgCacheHome
      ]
      (concat' xdgCacheHome "/fontconfig")
      (concat' xdgCacheHome "/mesa_shader_cache")
      (concat' xdgCacheHome "/mesa_shader_cache_db")
      (concat' xdgCacheHome "/radv_builtin_shaders")
      (concat' runtimeDir "/at-spi/bus")
      (concat' runtimeDir "/dconf")
      (concat' runtimeDir "/doc")
      (concat' runtimeDir "/gvfsd")
    ];
  };
}
