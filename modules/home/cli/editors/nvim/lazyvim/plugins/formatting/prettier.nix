{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.prettier;
in
{
  options.my.neovim.lazyvim.prettier = {
    enable = mkEnableOption "formatting tool - prettier";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPackages = with pkgs; [
        nodePackages.prettier
      ];

      imports = [ "lazyvim.plugins.extras.formatting.prettier" ];
    };
  };
}
