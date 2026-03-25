{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.neogen;
in
{
  options.my.lazyvim.neogen = {
    enable = mkEnableOption "Comment tool - mini.comment";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        neogen
      ];

      imports = [ "lazyvim.plugins.extras.coding.neogen" ];
    };
  };
}
