{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.tabnine;
in
{
  options.my.lazyvim.tabnine = {
    enable = mkEnableOption "AI plugin - tabnine";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        cmp-tabnine
      ];

      imports = [ "lazyvim.plugins.extras.ai.tabnine" ];
    };
  };
}
