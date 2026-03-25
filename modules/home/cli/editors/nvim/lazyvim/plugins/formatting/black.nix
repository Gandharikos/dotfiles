{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.black;
in
{
  options.my.lazyvim.black = {
    enable = mkEnableOption "formatting tool - black";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.formatting.black" ];

      extraPackages = with pkgs; [
        black
      ];
    };
  };
}
