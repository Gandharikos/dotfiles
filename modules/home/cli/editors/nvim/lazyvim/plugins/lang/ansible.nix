{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.ansible;
in
{
  options.my.lazyvim.ansible = {
    enable = mkEnableOption "language ansible";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.ansible" ];

      extraPackages = with pkgs; [
        ansible-lint
        ansible-language-server
      ];
    };
  };
}
