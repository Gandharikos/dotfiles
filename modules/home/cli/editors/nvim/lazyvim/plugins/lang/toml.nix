{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.toml;
in
{
  options.my.lazyvim.toml = {
    enable = mkEnableOption "language toml";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.toml" ];

      extraPackages = with pkgs; [
        taplo
      ];
    };
  };
}
