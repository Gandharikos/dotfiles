{
  config,
  lib,
  ...
}: let
  cfg = config.my.zoxide;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in {
  options.my.zoxide = {
    enable = mkEnableOption "zoxide";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;

      options = ["--cmd cd"];
    };
  };
}
