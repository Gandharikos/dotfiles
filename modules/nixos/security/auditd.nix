{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.security.auditd;
  rotationEnabled = cfg.autoPrune.enable && config.security.auditd.enable;
  logFile = config.security.auditd.settings.log_file or "/var/log/audit/audit.log";
  auditctl = lib.getExe' config.security.audit.package "auditctl";
  auditRules = pkgs.writeTextDir "audit.rules" ''
    -D
    ${lib.concatLines config.security.audit.rules}
  '';
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkForce mkIf;
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
      enable = mkEnableOption "bounded native auditd log rotation" // {
        default = true;
      };

      size = mkOption {
        type = lib.types.ints.positive;
        default = 67108864;
        description = "Maximum audit log size in bytes, rounded up to whole MiB by auditd.";
      };

      keep = mkOption {
        type = lib.types.ints.between 2 999;
        default = 8;
        description = "Number of audit log files retained by native rotation.";
      };

      dates = mkOption {
        type = str;
        default = "daily";
        example = "weekly";
        description = "How often to check for an oversized audit log in addition to native size-based rotation.";
      };
    };
  };

  config = mkIf cfg.enable {
    security = {
      auditd = {
        enable = true;
        settings = mkIf rotationEnabled {
          max_log_file = builtins.div (cfg.autoPrune.size + 1048575) 1048576;
          max_log_file_action = "rotate";
          num_logs = cfg.autoPrune.keep;
        };
      };

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

    # Never unlink a live audit log: auditd would keep writing to the deleted inode.
    systemd = {
      services.audit-rules-nixos.serviceConfig = {
        # The kernel parameters already set audit=1 and audit_backlog_limit.
        # auditctl currently rejects changing these at runtime, so only load rules here.
        ExecStart = mkForce "${auditctl} -R ${auditRules}/audit.rules";
        ExecStopPost = mkForce [ "${auditctl} -D" ];
      };

      timers."clean-audit-log" = mkIf rotationEnabled {
        description = "Periodically check audit log rotation";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.autoPrune.dates;
          Persistent = true;
        };
      };

      services."clean-audit-log" = mkIf rotationEnabled {
        requires = [ "auditd.service" ];
        after = [ "auditd.service" ];
        script = ''
          set -eu
          log_file=${lib.escapeShellArg logFile}
          if [[ -f "$log_file" ]] && [[ $(stat -c "%s" "$log_file") -ge ${toString cfg.autoPrune.size} ]]; then
            ${auditctl} --signal rotate
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
