{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.dot;
in
{
  options.my.lazyvim.dot = {
    enable = mkEnableOption "Language support for dotfiles";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.util.dot" ];

      extraPackages = with pkgs; [
        shellcheck
      ];
    };
  };
}
