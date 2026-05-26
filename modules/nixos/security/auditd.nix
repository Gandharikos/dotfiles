{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.security.auditd;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types)
    str
    int
    enum
    ;
in
{
  options.dot.security.auditd = {
    enable = mkEnableOption "Enable auditd" // {
      default = config.dot.security.enable;
    };

    backlogLimit = mkOption {
      type = int;
      default = 8192;
      description = ''
        Maximum number of outstanding audit buffers.
        Conservative default (8192) to prevent resource exhaustion.
        Enterprise environments may increase to 16384 or 32768.
      '';
    };

    failureMode = mkOption {
      type = enum [
        "silent"
        "printk"
        "panic"
      ];
      default = "printk";
      description = ''
        Action to take on critical errors.
        - silent: Discard audit records (safest for stability)
        - printk: Print to kernel log (can cause system hangs)
        - panic: Kernel panic (enterprise compliance mode)
      '';
    };

    autoPrune = {
      enable = mkEnableOption "Enable auto-pruning of audit logs via logrotate" // {
        default = true;
      };

      size = mkOption {
        type = int;
        default = 524288000; # ~500 megabytes
        description = "The maximum size of the audit log in bytes";
      };

      dates = mkOption {
        type = str;
        default = "daily";
        example = "weekly";
        description = "How often the audit log should be rotated";
      };
    };
  };

  config = mkIf cfg.enable {
    security = {
      auditd.enable = true;

      audit = {
        enable = true;
        inherit (cfg) backlogLimit;
        inherit (cfg) failureMode;
        rules = [
          # High overhead: monitor all program executions
          "-a exit,always -F arch=b64 -S execve"
        ];
      };
    };

    # the audit log can grow quite large, so we _can_ automatically prune it
    systemd = mkIf cfg.autoPrune.enable {
      timers."clean-audit-log" = {
        description = "Periodically clean audit log";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.autoPrune.dates;
          Persistent = true;
        };
      };

      services."clean-audit-log" = {
        script = ''
          set -eu
          if [[ $(stat -c "%s" /var/log/audit/audit.log) -gt ${toString cfg.autoPrune.size} ]]; then
            echo "Clearing Audit Log";
            rm -rvf /var/log/audit/audit.log;
            echo "Done!"
          fi
        '';

        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
