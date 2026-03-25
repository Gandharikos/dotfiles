{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.rust;
in
{
  options.my.lazyvim.rust = {
    enable = mkEnableOption "language rust";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        rustaceanvim
        crates-nvim
        neotest-rust
      ];

      imports = [ "lazyvim.plugins.extras.lang.rust" ];

      extraPackages = with pkgs; [
        bacon
        rust-analyzer
        vscode-extensions.vadimcn.vscode-lldb
      ];
    };
  };
}
