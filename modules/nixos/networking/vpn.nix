{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.networking.vpn;
  mullvad' = "${config.services.mullvad-vpn.package}/bin/mullvad";
  cat' = getExe' pkgs.coreutils "cat";
  sleep' = getExe' pkgs.coreutils "sleep";
  mullvadAutoLoginScript = pkgs.writeShellScript "mullvad-auto-login.sh" ''
    set -eu

    attempt=0
    until ${mullvad'} status >/dev/null 2>&1; do
      attempt=$((attempt + 1))
      if [ "$attempt" -ge 30 ]; then
        echo "Mullvad daemon did not become ready" >&2
        exit 1
      fi
      ${sleep'} 1
    done

    account_status="$(${mullvad'} account get 2>&1 || true)"
    case "$account_status" in
      ""|*"Not logged in"*|*"revoked"*)
        ${mullvad'} account logout >/dev/null 2>&1 || true
        ${mullvad'} account login "$(${cat'} ${config.sops.secrets.mullvad_vpn_account_number.path})" >/dev/null
        ;;
    esac

    ${mullvad'} auto-connect set off
    ${mullvad'} disconnect --wait || true
  '';
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

    services.mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = false;
      gui.enable = config.dot.gui.enable;
    };

    preservation.preserveAt."/persist".directories = mkIf config.dot.persistence.enable [
      "/etc/mullvad-vpn"
    ];

    sops.secrets.mullvad_vpn_account_number = {
      sopsFile = "${self}/secrets/services/mullvad.yaml";
      key = "mullvad_number";
    };

    systemd.services.mullvad-vpn-login = {
      description = "Log in to Mullvad VPN without connecting";
      after = [
        "mullvad-daemon.service"
        "sops-install-secrets.service"
      ];
      wants = [
        "mullvad-daemon.service"
        "sops-install-secrets.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = mullvadAutoLoginScript;
        Type = "oneshot";
        TimeoutStartSec = "2min";
      };
    };
  };
}
