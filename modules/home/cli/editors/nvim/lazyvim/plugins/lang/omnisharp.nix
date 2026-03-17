{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.omnisharp;
in
{
  options.my.neovim.lazyvim.omnisharp = {
    enable = mkEnableOption "language omnisharp";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        neotest-dotnet
        omnisharp-extended-lsp-nvim
      ];

      imports = [ "lazyvim.plugins.extras.lang.omnisharp" ];

      extraPackages = with pkgs; [
        csharpier
        netcoredbg
      ];
    };
  };
}
