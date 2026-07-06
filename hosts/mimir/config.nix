{ lib, ... }:
{
  dot = {
    primaryUser = "johnson";

    users.johnson = {
      shell = lib.mkForce "bash";
      home.my = {
        atuin.enable = lib.mkForce false;
        starship.enable = lib.mkForce false;
      };
    };

    device = {
      type = "vm";
      cpu = "vm-intel";
    };
  };

  environment = {
    etc."mimir/index.html".text = ''
      mimir: ok
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."mimir.local" = {
      default = true;
      locations = {
        "/" = {
          root = "/etc/mimir";
        };
        "/healthz" = {
          return = "200 'mimir: healthy\n'";
          extraConfig = ''
            add_header Content-Type text/plain;
          '';
        };
      };
    };
  };

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 2;
      memorySize = 2048;
      diskSize = 8192;
      graphics = false;
      forwardPorts = [
        {
          from = "host";
          host.port = 8080;
          guest.port = 80;
        }
        {
          from = "host";
          host.port = 10022;
          guest.port = 22;
        }
      ];
    };
  };

  system.stateVersion = "26.11";
}
