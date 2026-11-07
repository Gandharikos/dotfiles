{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.hunk;
in
{
  options.my.hunk.enable = mkEnableOption "Hunk terminal diff viewer";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.hunk ];
  };
}
