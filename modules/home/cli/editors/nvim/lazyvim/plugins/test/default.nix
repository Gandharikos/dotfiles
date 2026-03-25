{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.test;
in
{
  options.my.lazyvim.test = {
    enable = mkEnableOption "Neotest support";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        neotest
      ];

      imports = [ "lazyvim.plugins.extras.test.core" ];
    };
  };
}
