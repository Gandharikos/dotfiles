{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    enum
    nullOr
    path
    ;
  inherit (lib) mkIf;

  cfg = config.dot.networking.proxy;

in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.networking.proxy = {
    enable = mkEnableOption "proxy backend (mihomo or sing-box)";
    autoStart = mkEnableOption "proxy auto start on boot (NixOS only)";

    backend = mkOption {
      type = enum [
        "mihomo"
        "sing-box"
      ];
      default = "mihomo";
      description = "Proxy backend to activate for this host.";
    };

    mihomo.configFile = mkOption {
      type = nullOr path;
      default = null;
      description = "Runtime Mihomo configuration path; null requires an explicitly declared sops.secrets.proxy_config.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.backend != "mihomo" || cfg.mihomo.configFile != null || config ? sops.secrets.proxy_config;
        message = "Mihomo requires the shared proxy profile, mihomo.configFile, or an explicit sops.secrets.proxy_config; no legacy secret is loaded automatically.";
      }
      {
        assertion =
          cfg.backend != "sing-box"
          || cfg.singBox.configFile != null
          || config ? sops.secrets.proxy_source_config;
        message = "sing-box requires the shared proxy profile, singBox.configFile, or an explicit sops.secrets.proxy_source_config; no legacy secret is loaded automatically.";
      }
    ];
  };
}
