{
  config,
  lib,
  ...
}: let
  cfg = config.my.security.auditd;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) str;
in {
  options.my.security.auditd = {
    enable =
      mkEnableOption "Enable auditd"
      // {
        default = config.my.security.enable;
      };

    autoPrune = {
      enable =
        mkEnableOption "Enable auto-pruning of audit logs via logrotate"
        // {
          default = true;
        };

      dates = mkOption {
        type = str;
        default = "daily";
        example = "weekly";
        description = "How often the audit log should be rotated";
      };

      # Note: The byte-based 'size' option from your previous config has been removed.
      # In standard enterprise practices, rotating by days (daily) and keeping the last 7 days,
      # combined with compression, prevents disk exhaustion and makes log tracing much more organized.
    };
  };

  config = mkIf cfg.enable {
    security = {
      # Enable the system audit daemon
      auditd.enable = true;

      audit = {
        enable = true;
        # [Optimization] Increase the backlog limit to a robust 65536 to prevent log dropping under high system load
        backlogLimit = 65536;
        failureMode = "printk";
        rules = [
          # Monitor the execution of all programs (the most fundamental and critical audit)
          "-a exit,always -F arch=b64 -S execve"
          # Protect the audit log itself (prevent attackers from destroying evidence)
          "-w /var/log/audit -p wa -k auditlog"
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
