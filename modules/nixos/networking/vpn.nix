{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
  inherit (lib.options) mkEnableOption;
  accountNumberSecret = config.sops.secrets.mullvad_vpn_account_number;
  cfg = config.dot.networking.vpn;
in
{
  options.dot.networking.vpn = {
    enable = mkEnableOption "Mullvad VPN" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    dot.networking.tailscale = {
      acceptDns = false;
      acceptRoutes = false;
    };

    sops.secrets.mullvad_vpn_account_number = {
      sopsFile = "${self}/secrets/services/mullvad.yaml";
      key = "mullvad_number";
    };

    services.mullvad-vpn.enable = true;

    environment.systemPackages =
      with pkgs;
      [
        mullvad
      ]
      ++ optionals config.dot.gui.enable [
        mullvad-vpn
      ];

    systemd.services.mullvad-vpn-login = {
      description = "Log in to Mullvad VPN";
      after = [
        "mullvad-daemon.service"
        "sops-install-secrets.service"
      ];
      requires = [ "sops-install-secrets.service" ];
      wants = [ "mullvad-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        config.services.mullvad-vpn.package
        pkgs.coreutils
      ];
      script = ''
        is_logged_in() {
          account_status="$(mullvad account get 2>/dev/null || true)"
          case "$account_status" in
            ""|*"Not logged in"*) return 1 ;;
            *) return 0 ;;
          esac
        }

        for _ in $(seq 1 30); do
          if mullvad status >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        if is_logged_in; then
          exit 0
        fi

        account_number="$(tr -d '[:space:]' < ${accountNumberSecret.path})"
        if [ -z "$account_number" ]; then
          echo "Mullvad account number secret is empty" >&2
          exit 1
        fi

        mullvad account login "$account_number"
      '';
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "2min";
      };
    };
  };
}
