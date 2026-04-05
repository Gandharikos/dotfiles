{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.prettier;
in
{
  options.my.lazyvim.prettier = {
    enable = mkEnableOption "formatting tool - prettier";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPackages = with pkgs; [
        prettier
      ];

      imports = [ "lazyvim.plugins.extras.formatting.prettier" ];
    };
  };
}
