{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.services.fail2ban;
in
{
  options.my.services.fail2ban = {
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
      jails = {
        sshd.settings = {
          mode = "aggressive";
          filter = "sshd";
          backend = "systemd";
          maxretry = 3;
        };

        # nginx-http-auth = ''
        #   enabled = true
        #   port    = http,https
        #   filter  = nginx-http-auth
        #   backend = systemd
        #   journalmatch = _SYSTEMD_UNIT=nginx.service
        # '';
        #
        # nginx-botsearch = ''
        #   enabled = true
        #   port    = http,https
        #   filter  = nginx-botsearch
        #   backend = systemd
        #   journalmatch = _SYSTEMD_UNIT=nginx.service
        # '';
        #
        # nginx-bad-request = ''
        #   enabled = true
        #   port    = http,https
        #   filter  = nginx-bad-request
        #   backend = systemd
        #   journalmatch = _SYSTEMD_UNIT=nginx.service
        # '';
        #
        # authelia = ''
        #   enabled = true
        #   port    = http,https
        #   filter  = authelia
        #   backend = systemd
        #   journalmatch = _SYSTEMD_UNIT=authelia-main.service + _COMM=authelia
        # '';
      };
      # environment.etc = {
      #   "fail2ban/filter.d/authelia.conf".text = ''
      #     [Definition]
      #     failregex = ^.*Unsuccessful 1FA authentication attempt by user .*remote_ip="?<HOST>"? stack.*
      #                 ^.*Unsuccessful (TOTP|Duo|U2F) authentication attempt by user .*remote_ip="?<HOST>"? stack.*
      #
      #     ignoreregex = ^.*level=debug.*
      #                   ^.*level=info.*
      #                   ^.*level=warning.*
      #   '';
      # };
    };
  };
}
