{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.go;
in
{
  options.my.neovim.lazyvim.go = {
    enable = mkEnableOption "language go";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        nvim-dap-go
        neotest-golang
      ];

      imports = [ "lazyvim.plugins.extras.lang.go" ];

      extraPackages = with pkgs; [
        delve
        gopls
        gotools
        gofumpt
        gomodifytags
        impl
      ];
    };
  };
}
