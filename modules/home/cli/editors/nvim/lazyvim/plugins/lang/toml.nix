{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.toml;
in
{
  options.my.neovim.lazyvim.toml = {
    enable = mkEnableOption "language toml";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.toml" ];

      extraPackages = with pkgs; [
        taplo
      ];
    };
  };
}
