{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.sidekick;
in
{
  options.my.lazyvim.sidekick = {
    enable = mkEnableOption "AI plugin - sidekick";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.ai.sidekick" ];

      extraPlugins = with pkgs.vimPlugins; [
        sidekick-nvim
      ];
    };
  };
}
