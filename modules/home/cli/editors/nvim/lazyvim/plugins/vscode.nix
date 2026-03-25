{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.vscode;
in
{
  options.my.lazyvim.vscode = {
    enable = mkEnableOption "LazyVim integration with Visual Studio Code";
  };

  config = mkIf cfg.enable {
    my.lazyvim.imports = [ "lazyvim.plugins.extras.vscode" ];
  };
}
