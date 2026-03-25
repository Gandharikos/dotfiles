{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.clangd;
in
{
  options.my.lazyvim.clangd = {
    enable = mkEnableOption "language clangd";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        clangd_extensions-nvim
      ];

      extraPackages = with pkgs; [
        vscode-extensions.vadimcn.vscode-lldb
        clang-tools
      ];

      imports = [ "lazyvim.plugins.extras.lang.clangd" ];
    };
  };
}
