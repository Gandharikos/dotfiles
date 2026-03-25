{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.angular;
in
{
  options.my.lazyvim.angular = {
    enable = mkEnableOption "language angular";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      typescript.enable = true;

      imports = [ "lazyvim.plugins.extras.lang.angular" ];

      extraPackages = with pkgs; [
        angular-language-server
      ];
    };
  };
}
