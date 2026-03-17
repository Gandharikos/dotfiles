{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.typescript;
in
{
  options.my.neovim.lazyvim.typescript = {
    enable = mkEnableOption "language typescript";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.typescript" ];

      extraPackages = with pkgs; [
        typescript-language-server
        vtsls
      ];
    };
  };
}
