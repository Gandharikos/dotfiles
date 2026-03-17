{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.r;
  inherit (lib.meta) getExe;
  R' = getExe pkgs.R;
  r-language-server = pkgs.writeShellScriptBin "r-language-server" ''
    exec ${R'} --slave -e 'languageserver::run()'
  '';
in
{
  options.my.neovim.lazyvim.r = {
    enable = mkEnableOption "language r";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        R-nvim
        # cmp-r
        neotest-testthat
      ];

      imports = [ "lazyvim.plugins.extras.lang.r" ];

      extraPackages = [
        r-language-server
      ];
    };
  };
}
