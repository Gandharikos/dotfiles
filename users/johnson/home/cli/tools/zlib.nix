{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.zlib;
  plugin = "${pkgs.dot.zlib-cli.src}/plugins/zlib";
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.zlib.enable = mkEnableOption "HeartLeo's Z-Library CLI";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.dot.zlib-cli ];

    programs.claude-code.plugins.zlib = mkIf config.programs.claude-code.enable plugin;
    programs.codex.plugins = mkIf config.programs.codex.enable [ plugin ];
  };
}
