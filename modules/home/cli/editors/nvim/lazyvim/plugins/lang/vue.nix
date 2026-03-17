{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.vue;
in
{
  options.my.neovim.lazyvim.vue = {
    enable = mkEnableOption "language vue";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      typescript.enable = true;

      imports = [ "lazyvim.plugins.extras.lang.vue" ];

      extraPackages = with pkgs; [
        vscode-extensions.vue.volar
        vtsls
      ];
    };
  };
}
