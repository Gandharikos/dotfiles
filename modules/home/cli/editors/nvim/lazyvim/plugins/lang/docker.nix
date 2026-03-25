{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.docker;
in
{
  options.my.lazyvim.docker = {
    enable = mkEnableOption "language docker";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.docker" ];

      extraPackages = with pkgs; [
        hadolint
      ];
    };
  };
}
