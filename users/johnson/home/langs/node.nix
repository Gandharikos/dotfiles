{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.node;
  enable = config.my.langs.enable && cfg.enable;
  nodePkg = pkgs.nodejs_latest;
  inherit (lib.modules) mkMerge mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.meta) getExe getExe';
  inherit (config) xdg;
  yarn' = getExe pkgs.yarn;
in
{
  options.my.langs.node = {
    enable = mkEnableOption "Node.js development environment";
  };

  config = mkMerge [
    (mkIf enable {
      home.packages = [
        nodePkg
        pkgs.yarn
      ];

      # Run locally installed bin-script, e.g. n coffee file.coffee
      home.shellAliases = {
        n = "PATH=\"$(${getExe' nodePkg "npm"} bin):$PATH\"";
        ya = "yarn";
      };

      home.sessionVariables.PATH = [ "$(${yarn'} global bin)" ];
    })

    (mkIf enable {
      # NPM refuses to adopt XDG conventions upstream, so I enforce it myself.
      home.sessionVariables = {
        NPM_CONFIG_USERCONFIG = "${xdg.configHome}/npm/config";
        NPM_CONFIG_CACHE = "${xdg.cacheHome}/npm";
        NPM_CONFIG_PREFIX = "${xdg.dataHome}/npm";
        NPM_CONFIG_TMP = "${xdg.cacheHome}/npm/tmp";
        NODE_REPL_HISTORY = "${xdg.stateHome}/node/repl_history";
      };

      home.file."npm/config".text = ''
        cache=${xdg.cacheHome}/npm
        prefix=${xdg.dataHome}/npm
        tmp=${xdg.cacheHome}/npm/tmp
      '';
    })
  ];
}
