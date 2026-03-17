{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.ansible;
in
{
  options.my.neovim.lazyvim.ansible = {
    enable = mkEnableOption "language ansible";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.ansible" ];

      extraPackages = with pkgs; [
        ansible-lint
        ansible-language-server
      ];
    };
  };
}
