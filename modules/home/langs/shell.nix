{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dot.langs.shell;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
in
{
  options.dot.langs.shell = {
    enable = mkEnableOption "Shell development environment";
    xdg.enable = mkEnableOption "Shell XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        shellcheck
      ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
