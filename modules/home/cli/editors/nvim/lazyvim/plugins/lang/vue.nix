{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.vue;
in
{
  options.my.lazyvim.vue = {
    enable = mkEnableOption "language vue";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      typescript.enable = true;

      imports = [ "lazyvim.plugins.extras.lang.vue" ];

      extraPackages = with pkgs; [
        vscode-extensions.vue.volar
        vtsls
      ];
    };
  };
}
