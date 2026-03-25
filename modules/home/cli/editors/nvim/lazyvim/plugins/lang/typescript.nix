{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.typescript;
in
{
  options.my.lazyvim.typescript = {
    enable = mkEnableOption "language typescript";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.typescript" ];

      extraPackages = with pkgs; [
        typescript-language-server
        vtsls
      ];
    };
  };
}
