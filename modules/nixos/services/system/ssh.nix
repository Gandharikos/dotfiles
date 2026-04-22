{
  lib,
  # pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.strings) optionalString;
  persist = config.my.persistence.enable;
  cfg = config.my.services.ssh;
in
{
  options.my.services.ssh = {
    enable = mkEnableOption "ssh" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # environment.systemPackages = [pkgs.ghossty.terminfo];
    services.openssh = {
      enable = true;
      startWhenNeeded = true;

      allowSFTP = true;

      settings = {
        Banner = "/etc/ssh/banner";

        # allow root login to remote deployments
        PermitRootLogin = "no";

        # only allow key based logins and not password
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AuthenticationMethods = "publickey";
        PubkeyAuthentication = "yes";
        ChallengeResponseAuthentication = "no";
        UsePAM = true;
        UseDns = false;
        X11Forwarding = false;

        # Use key exchange algorithms recommended by `nixpkgs#ssh-audit`
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "sntrup761x25519-sha512@openssh.com"
          "diffie-hellman-group-exchange-sha256"
          "mlkem768x25519-sha256"
          "sntrup761x25519-sha512"
        ];

        # Use Macs recommended by `nixpkgs#ssh-audit`
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];

        # kick out inactive sessions
        ClientAliveCountMax = 5;
        ClientAliveInterval = 60;
        IgnoreRhosts = "yes";
        MaxAuthTries = 3;

        AllowUsers = [ config.my.name ];
      };
      openFirewall = true;
      hostKeys = [
        {
          bits = 4096;
          path = "${optionalString persist "/persist"}/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          bits = 4096;
          path = "${optionalString persist "/persist"}/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
      ];
    };

    environment.etc."ssh/banner".text = ''
      Welcome to ${config.networking.hostName} @ ${config.my.stateVersion}!
    '';

    # yubikey login / sudo
    security.pam = {
      rssh.enable = true;
      services = {
        sudo.rssh = true;
        sudo-i.rssh = true;
      };
    };
  };
}
