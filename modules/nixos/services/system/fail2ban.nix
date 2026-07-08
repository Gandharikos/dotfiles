{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.services.fail2ban;
  vaultwarden = config.dot.selfhosted.services.vaultwarden;
in
{
  options.dot.services.fail2ban = {
    enable = mkEnableOption "fail2ban" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "24h";
      bantime-increment = {
        enable = true;
        formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
        maxtime = "168h";
        overalljails = true;
      };
      #ignore local ips
      ignoreIP = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "100.64.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "8.8.8.8"
      ];
      jails = mkMerge [
        {
          sshd.settings = {
            mode = "aggressive";
            filter = "sshd";
            backend = "systemd";
            maxretry = 3;
          };
        }
        (mkIf vaultwarden.enable {
          vaultwarden = {
            filter = {
              INCLUDES.before = "common.conf";
              Definition = {
                failregex = "^.*Username or password is incorrect\\. Try again\\. IP: <ADDR>\\. Username:.*$";
                ignoreregex = "";
              };
            };
            settings = {
              port = "80,443,${toString vaultwarden.port}";
              backend = "systemd";
              journalmatch = "_SYSTEMD_UNIT=vaultwarden.service";
              banaction = "%(banaction_allports)s";
              maxretry = 3;
              bantime = 14400;
              findtime = 14400;
            };
          };

          vaultwarden-admin = {
            filter = {
              INCLUDES.before = "common.conf";
              Definition = {
                failregex = "^.*Invalid admin token\\. IP: <ADDR>.*$";
                ignoreregex = "";
              };
            };
            settings = {
              port = "80,443,${toString vaultwarden.port}";
              backend = "systemd";
              journalmatch = "_SYSTEMD_UNIT=vaultwarden.service";
              banaction = "%(banaction_allports)s";
              maxretry = 3;
              bantime = 14400;
              findtime = 14400;
            };
          };
        })
      ];
    };
  };
}
