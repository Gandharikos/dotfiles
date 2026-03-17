{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.typst;
in
{
  options.my.typst = {
    enable = mkEnableOption "typst";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      typst
      typstyle
    ];
  };
}
