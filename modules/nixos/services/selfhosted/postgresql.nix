{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.postgresql;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.selfhosted.services.postgresql.enable =
    mkEnableOption "PostgreSQL for self-hosted services"
    // {
      default = config.dot.selfhosted.enable;
    };

  config = mkIf cfg.enable {
    services.postgresql.enable = true;
  };
}
