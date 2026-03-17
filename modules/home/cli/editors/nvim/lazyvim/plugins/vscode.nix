{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.vscode;
in
{
  options.my.neovim.lazyvim.vscode = {
    enable = mkEnableOption "LazyVim integration with Visual Studio Code";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim.imports = [ "lazyvim.plugins.extras.vscode" ];
  };
}
