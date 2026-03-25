{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.startuptime;
in
{
  options.my.lazyvim.startuptime = {
    enable = mkEnableOption "startuptime";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        startuptime-nvim
      ];

      imports = [ "lazyvim.plugins.extras.util.startuptime" ];
    };
  };
}
