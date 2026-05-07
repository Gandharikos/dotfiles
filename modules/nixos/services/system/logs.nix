{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  isServer = config.dot.machine.type == "server";
in
{
  config = mkIf isServer {
    # limit systemd journal size
    # https://wiki.archlinux.org/title/Systemd/Journal#Persistent_journals
    services.journald.extraConfig = ''
      SystemMaxUse=100M
      RuntimeMaxUse=50M
      SystemMaxFileSize=50M
    '';
  };
}
