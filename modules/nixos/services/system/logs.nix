{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  isServer = config.dot.device.type == "server";
in
{
  config = mkIf isServer {
    # limit systemd journal size
    # https://wiki.archlinux.org/title/Systemd/Journal#Persistent_journals
    services.journald.settings.Journal = {
      SystemMaxUse = "100M";
      RuntimeMaxUse = "50M";
      SystemMaxFileSize = "50M";
    };
  };
}
