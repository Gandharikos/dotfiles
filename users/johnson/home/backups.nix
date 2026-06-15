{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.backups.taildrop;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str;
  inherit (lib.meta) getExe;

  receiveBackups = pkgs.writeShellApplication {
    name = "taildrop-backup-get";
    runtimeInputs = with pkgs; [
      coreutils
      tailscale
    ];
    text = ''
      install -d -m 0700 "${cfg.directory}"
      tailscale file get --conflict=rename "${cfg.directory}"
    '';
  };
in
{
  options.my.backups.taildrop = {
    enable = mkEnableOption "Tailscale Taildrop backup receiver";

    directory = mkOption {
      type = str;
      default = "${config.home.homeDirectory}/Documents/Backups/athena";
      description = "Directory where Taildrop backup files are stored.";
    };

    schedule = mkOption {
      type = str;
      default = "*:0/15";
      description = "systemd calendar expression for pulling Taildrop backup files.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.taildrop-backup-get = {
      Unit = {
        Description = "Receive Taildrop backup files";
      };

      Service = {
        Type = "oneshot";
        ExecStart = getExe receiveBackups;
      };
    };

    systemd.user.timers.taildrop-backup-get = {
      Unit = {
        Description = "Receive Taildrop backup files";
      };

      Timer = {
        OnCalendar = cfg.schedule;
        OnStartupSec = "2m";
        Persistent = true;
        Unit = "taildrop-backup-get.service";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
