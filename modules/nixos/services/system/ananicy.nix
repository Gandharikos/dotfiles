{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.ananicy;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.services.ananicy.enable = mkEnableOption "Ananicy-cpp automatic process management" // {
    default = config.dot.gui.enable;
  };

  config = mkIf cfg.enable {
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
  };
}
