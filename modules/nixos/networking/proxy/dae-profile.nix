{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (cfg) profile;
  inherit (profile) dae;
  python = pkgs.python3.withPackages (p: [ p.pyyaml ]);
  parameters = pkgs.writeText "dae-parameters.json" (
    builtins.toJSON {
      inherit (dae) selections tproxyPort;
      wan = dae.wanInterfaces;
      lan = dae.lanInterfaces;
      dnsPort = profile.ports.dns;
      tailnetDomain = profile.tailnet.domain;
    }
  );
  generate = pkgs.writeShellApplication {
    name = "dae-profile";
    text = ''
      exec ${lib.getExe python} ${self}/scripts/dae-profile.py \
        --template ${dae.template} --policy ${dae.policy} --groups ${dae.groups} \
        --parameters ${parameters} --nodes "$CREDENTIALS_DIRECTORY/nodes.yaml" \
        --output /run/dae/config.dae --core ${lib.getExe config.services.dae.package}
    '';
  };
in
{
  options.dot.networking.proxy.profile.dae = {
    template = lib.mkOption {
      type = lib.types.path;
      default = "${self}/config/dae/config.dae";
      description = "Public native dae template; private nodes are inserted at runtime.";
    };
    policy = lib.mkOption {
      type = lib.types.path;
      default = "${self}/config/dae/policy.dae";
      description = "Ordered native routing policy with strategy-group placeholders.";
    };
    groups = lib.mkOption {
      type = lib.types.path;
      default = "${self}/config/dae/groups.json";
      description = "Public group membership, saved selections and policy target mapping.";
    };
    selections = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Override saved select-group choices by original group and member name.";
    };
    wanInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "auto" ];
      description = "Interfaces for host-local interception; auto follows the default route.";
    };
    lanInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Explicit interfaces for forwarded LAN traffic; empty by default.";
    };
    tproxyPort = lib.mkOption {
      type = lib.types.port;
      default = 12345;
      description = "Internal eBPF transparent-proxy port, not an HTTP/SOCKS listener.";
    };
  };

  config = lib.mkIf (cfg.enable && profile.enable && cfg.backend == "dae") {
    dot.networking.proxy.dae.configFile = "/run/dae/config.dae";
    sops.secrets.dae_subscription_nodes = {
      sopsFile = profile.secretsFile;
      key = "subscription_nodes";
      restartUnits = [ "dae.service" ];
    };

    # Credentials for dae itself are loaded before ExecStartPre, so render in a prerequisite unit.
    systemd.services.dae-config = {
      description = "Render and validate the private dae profile";
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      environment.DAE_LOCATION_ASSET = config.services.dae.assetsPath;
      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = "dae";
        RuntimeDirectoryMode = "0700";
        RuntimeDirectoryPreserve = "yes";
        LoadCredential = [ "nodes.yaml:${config.sops.secrets.dae_subscription_nodes.path}" ];
        ExecStart = lib.getExe generate;
        UMask = "0077";
      };
    };
    systemd.services.dae = {
      requires = [ "dae-config.service" ];
      after = [ "dae-config.service" ];
      restartTriggers = [
        dae.template
        dae.policy
        dae.groups
        parameters
        generate
      ];
    };

    assertions = [
      {
        assertion = dae.wanInterfaces != [ ] || dae.lanInterfaces != [ ];
        message = "The dae profile requires an explicit WAN or LAN interface selection.";
      }
      {
        assertion = dae.tproxyPort != profile.ports.dns;
        message = "The dae DNS and transparent-proxy ports must be distinct.";
      }
      {
        assertion = !profile.tailnet.webUI.enable;
        message = "dae has no Clash controller or embedded Tailnet WebUI; disable profile.tailnet.webUI.";
      }
      {
        assertion = !config.services.sing-box.enable && !config.services.mihomo.enable;
        message = "Do not run dae alongside another transparent proxy backend.";
      }
    ];
  };
}
