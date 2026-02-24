{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.services.proxy;
  inherit (lib.modules) mkIf;
  configFile = "/var/lib/mihomo/config.yaml";
  # Get the URL directly from the secret value.
  # sops-nix finds this in `config.sops.defaultSopsFile`.
  subUrl = config.sops.secrets.mihomo_subUrl;

  updateScript = pkgs.writeShellScript "update-mihomo-config" ''
    #!${pkgs.runtimeShell}
    set -e
    echo "Updating mihomo config from ${subUrl}"
    ${pkgs.curl}/bin/curl -sfL -o ${configFile} '${subUrl}'
    chown mihomo:mihomo ${configFile}
  '';
in {
  config = mkIf cfg.enable {
    # Declare the secret key required from the default sops file.
    sops.secrets.mihomo_subUrl = {};

    # https://wiki.metacubex.one/config
    # https://nixos.wiki/wiki/Mihomo
    services.mihomo = {
      enable = true;
      webui = pkgs.metacubexd;
      # package = pkgs.mihomo;
      # tunMode = true;
      inherit configFile;
    };

    networking.firewall.allowedTCPPorts = [9090];

    systemd.services.mihomo = {
      # Ensure the secret is decrypted before this service starts.
      # sops-nix will make the `data` available after it runs.
      after = ["sops-nix.service"];
      wants = ["sops-nix.service"];

      # Do not start on boot; let the dispatcher script control it.
      wantedBy = lib.mkForce [];

      # Run before starting mihomo
      preStart = ''
        ${updateScript}
      '';
    };

    systemd.services."update-mihomo-config" = {
      description = "Update mihomo subscription config";
      script = updateScript;
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      # Also needs to run after secrets are available.
      after = ["sops-nix.service"];
    };

    systemd.timers."update-mihomo-config" = {
      description = "Update mihomo subscription config weekly";
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };
  };
}
