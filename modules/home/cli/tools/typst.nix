{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.dot.typst;
in
{
  options.dot.typst = {
    enable = mkEnableOption "typst";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      typst
      typstyle
    ];
  };
}
