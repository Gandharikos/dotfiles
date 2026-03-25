{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.go;
in
{
  options.my.lazyvim.go = {
    enable = mkEnableOption "language go";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
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
