{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.yanky;
in
{
  options.my.lazyvim.yanky = {
    enable = mkEnableOption "better yank/paste";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        yanky-nvim
      ];

      imports = [ "lazyvim.plugins.extras.coding.yanky" ];
    };
  };
}
