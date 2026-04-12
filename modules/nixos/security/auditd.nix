{
  config,
  lib,
  ...
}:
let
  cfg = config.my.security.auditd;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types)
    str
    int
    enum
    ;
in
{
  options.my.security.auditd = {
    enable = mkEnableOption "Enable auditd" // {
      default = config.my.security.enable;
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
      default = "silent";
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

    # [Core Best Practice] Utilize logrotate for log lifecycle management
    services.logrotate.settings.audit = mkIf cfg.autoPrune.enable {
      files = "/var/log/audit/*.log";
      frequency = cfg.autoPrune.dates; # Rotate daily by default
      rotate = 7; # Keep the last 7 rotated logs
      compress = true; # Auto-compress (saves massive amounts of space)
      delaycompress = true; # Delay compression by one day to prevent compressing while auditd is still writing
      missingok = true; # Do not error out if the log file is missing
      notifempty = true; # Do not rotate if the log is empty
      create = "0640 root root"; # Extremely strict permissions for the newly created log file
      postrotate = ''
        # After rotation, gently notify the auditd process to reopen its file descriptors
        /bin/kill -HUP `cat /var/run/auditd.pid 2> /dev/null` 2> /dev/null || true
      '';
    };
  };
}
