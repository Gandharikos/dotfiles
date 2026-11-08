{
  lib,
  config,
  ...
}:
let
  inherit (lib.strings) optionalString;
  persist = config.dot.persistence.enable;
in
{
  programs.ssh.knownHosts = {
    "github.com" = {
      # Published at https://api.github.com/meta.
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    "git.huwenqiang.dev" = {
      # Matches the host key in secrets/johnson/core/athena.pub.
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIhVE2Ab0ikxrXeUMppzCt6pOPZ8pU/siygTSNamXbpK";
    };
  };

  # environment.systemPackages = [pkgs.ghossty.terminfo];
  services.openssh = {
    enable = lib.mkDefault true;
    startWhenNeeded = true;
    ports = [
      22
      2222
    ];

    allowSFTP = true;

    settings = {
      Banner = "/etc/ssh/banner";

      PermitRootLogin = "no";

      # only allow key based logins and not password
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      AllowStreamLocalForwarding = "yes";
      PubkeyAuthentication = "yes";
      ChallengeResponseAuthentication = "no";
      UsePAM = true;
      UseDns = false;
      StreamLocalBindUnlink = "yes";
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

      # Drop chacha20-poly1305 to sidestep Terrapin (CVE-2023-48795) for
      # unpatched peers; keep AES-GCM/CTR which ssh-audit considers safe.
      Ciphers = [
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];

      # Throttle per-source connection attempts to mitigate the DHEat DoS
      # (CVE-2002-20001).
      PerSourceMaxStartups = 1;
      PerSourceNetBlockSize = "32:128";

      # kick out inactive sessions
      ClientAliveCountMax = 5;
      ClientAliveInterval = 60;

      AllowUsers = config.dot.enabledUsers;
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
    Welcome to ${config.networking.hostName} @ ${config.dot.stateVersion}!
  '';

  # yubikey login / sudo
  security.pam = {
    rssh.enable = true;
    services = {
      sudo.rssh = true;
      sudo-i.rssh = true;
    };
  };
}
