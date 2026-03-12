# modules/dev/java.nix --- Poster child for carpal tunnel
#
# TODO
{
  lib,
  config,
  ...
}: let
  cfg = config.my.langs.java;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
in {
  options.my.langs.java = {
    enable = mkEnableOption "java development environment";
    xdg.enable = mkEnableOption "java XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # TODO
    })

    (mkIf cfg.xdg.enable {
      home.sessionVariables._JAVA_OPTIONS = ''-Djava.util.prefs.userRoot="${config.xdg.configHome}/java"'';
    })
  ];
}
