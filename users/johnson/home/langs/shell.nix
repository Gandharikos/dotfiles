{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.shell;
  enable = config.my.langs.enable && cfg.enable;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
in
{
  options.my.langs.shell = {
    enable = mkEnableOption "Shell development environment";
  };

  config = mkMerge [
    (mkIf enable {
      home.packages = with pkgs; [
        shellcheck
      ];
    })

    (mkIf enable {
      # TODO
    })
  ];
}
