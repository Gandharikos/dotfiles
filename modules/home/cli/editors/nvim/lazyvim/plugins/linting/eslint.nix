{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.eslint;
in
{
  options.my.lazyvim.eslint = {
    enable = mkEnableOption "linting tool - eslint";
  };

  config = mkIf cfg.enable {
    my.lazyvim.imports = [ "lazyvim.plugins.extras.linting.eslint" ];
  };
}
