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
  inherit (lib.strings) escapeShellArg;
  accountNumberSecret = config.sops.secrets.mullvad_vpn_account_number;
  cfg = config.dot.networking.vpn;
  deviceLimitMessage = "There are too many devices on the account";
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
        pkgs.gnugrep
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

        login_output="$(mktemp)"
        set +e
        mullvad account login "$account_number" >"$login_output" 2>&1
        login_status="$?"
        set -e

        if [ "$login_status" -eq 0 ]; then
          rm -f "$login_output"
          exit 0
        fi

        cat "$login_output" >&2

        if grep -Fq ${escapeShellArg deviceLimitMessage} "$login_output"; then
          echo >&2
          echo "Mullvad account device limit reached." >&2
          echo "Revoke one unused device, then restart this service:" >&2
          echo "  sudo sh -c 'account=\$(tr -d \"[:space:]\" < ${accountNumberSecret.path}); mullvad account revoke-device --account \"\$account\" <device-id-or-name>'" >&2
          echo "  sudo systemctl restart mullvad-vpn-login.service" >&2
          echo >&2
          echo "Current devices on the account:" >&2
          mullvad account list-devices --account "$account_number" --verbose >&2 || true
          rm -f "$login_output"
          exit 75
        fi

        rm -f "$login_output"
        exit "$login_status"
      '';
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "2min";
        SuccessExitStatus = [ 75 ];
      };
    };
  };
}
