# modules/dev/node.nix --- https://nodejs.org/en/
#
# JS is one of those "when it's good, it's alright, when it's bad, it's a
# disaster" languages.
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.langs.node;
  nodePkg = pkgs.nodejs_latest;
  inherit (lib.modules) mkMerge mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.meta) getExe;
  inherit (config) xdg;
  yarn' = getExe pkgs.yarn;
in {
  options.my.langs.node = {
    enable = mkEnableOption "Node.js development environment";
    xdg.enable = mkEnableOption "Node.js XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [
        nodePkg
        pkgs.yarn
      ];

      # Run locally installed bin-script, e.g. n coffee file.coffee
      home.shellAliases = {
        n = "PATH=\"$(${nodePkg}/bin/npm bin):$PATH\"";
        ya = "yarn";
      };

      home.sessionVariables.PATH = ["$(${yarn'} global bin)"];
    })

    (mkIf cfg.xdg.enable {
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
