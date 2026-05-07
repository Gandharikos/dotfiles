{
  config,
  lib,
  ...
}:
let
  shellAliases = {
    "top" = "btop";
  };
  cfg = config.dot.btop;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.dot.btop = {
    enable = mkEnableOption "btop";
  };

  config = mkIf cfg.enable {
    programs.btop = {
      enable = true;
    };

    home = {
      inherit shellAliases;
    };
  };
}
