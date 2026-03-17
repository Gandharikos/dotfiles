{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.black;
in
{
  options.my.neovim.lazyvim.black = {
    enable = mkEnableOption "formatting tool - black";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.formatting.black" ];

      extraPackages = with pkgs; [
        black
      ];
    };
  };
}
