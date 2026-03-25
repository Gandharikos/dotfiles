{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.dial;
in
{
  options.my.lazyvim.dial = {
    enable = mkEnableOption "Increment and decrement numbers, dates, and more";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.editor.dial" ];

      extraPlugins = with pkgs.vimPlugins; [
        dial-nvim
      ];
    };
  };
}
