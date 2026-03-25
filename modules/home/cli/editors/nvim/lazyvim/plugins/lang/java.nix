{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.java;
in
{
  options.my.lazyvim.java = {
    enable = mkEnableOption "language java";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        nvim-jdtls
      ];

      imports = [ "lazyvim.plugins.extras.lang.java" ];

      extraPackages = with pkgs; [
        vscode-extensions.vscjava.vscode-java-debug
        vscode-extensions.vscjava.vscode-java-test
      ];
    };
  };
}
