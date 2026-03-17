{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.docker;
in
{
  options.my.neovim.lazyvim.docker = {
    enable = mkEnableOption "language docker";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.docker" ];

      extraPackages = with pkgs; [
        hadolint
      ];
    };
  };
}
