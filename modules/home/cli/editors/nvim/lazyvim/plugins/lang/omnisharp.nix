{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.omnisharp;
in
{
  options.my.lazyvim.omnisharp = {
    enable = mkEnableOption "language omnisharp";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
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
