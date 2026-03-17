{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.angular;
in
{
  options.my.neovim.lazyvim.angular = {
    enable = mkEnableOption "language angular";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      typescript.enable = true;

      imports = [ "lazyvim.plugins.extras.lang.angular" ];

      extraPackages = with pkgs; [
        angular-language-server
      ];
    };
  };
}
