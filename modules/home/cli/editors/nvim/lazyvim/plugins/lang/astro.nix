{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.astro;
in
{
  options.my.lazyvim.astro = {
    enable = mkEnableOption "language astro";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      typescript.enable = true;

      imports = [ "lazyvim.plugins.extras.lang.astro" ];

      extraPackages = with pkgs; [
        astro-language-server
      ];
    };
  };
}
