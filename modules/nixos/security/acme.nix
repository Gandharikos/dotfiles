{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkIf;
  inherit (lib.types) str bool;

  cfg = config.khanelinix.security.acme;
in
{
  options.my.security.acme = {
    enable = mkEnableOption "default ACME configuration";
    email = mkOption {
      type = str;
      default = config.my.email;
      description = "Email address to use for ACME registration.";
    };
    staging = mkOption {
      type = bool;
      default = false;
      description = "Whether to use the staging server or not.";
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;

      defaults = {
        inherit (cfg) email;

        group = mkIf config.services.nginx.enable "nginx";
        # Reload nginx when certs change.
        reloadServices = optional config.services.nginx.enable "nginx.service";
        server = mkIf cfg.staging "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
    };
  };
}
