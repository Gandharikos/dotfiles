{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.zoxide;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.dot.zoxide = {
    enable = mkEnableOption "zoxide";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;

      options = [ "--cmd cd" ];
    };
  };
}
