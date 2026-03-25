{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.json;
in
{
  options.my.lazyvim.json = {
    enable = mkEnableOption "language json";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        SchemaStore-nvim
        crates-nvim
      ];

      imports = [ "lazyvim.plugins.extras.lang.json" ];

      extraPackages = with pkgs; [
        bacon
        rust-analyzer
        vscode-extensions.vadimcn.vscode-lldb
      ];
    };
  };
}
