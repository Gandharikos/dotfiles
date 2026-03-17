{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.eslint;
in
{
  options.my.neovim.lazyvim.eslint = {
    enable = mkEnableOption "linting tool - eslint";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim.imports = [ "lazyvim.plugins.extras.linting.eslint" ];
  };
}
