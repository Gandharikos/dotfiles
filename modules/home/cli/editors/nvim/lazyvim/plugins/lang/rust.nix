{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.rust;
in
{
  options.my.neovim.lazyvim.rust = {
    enable = mkEnableOption "language rust";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
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
