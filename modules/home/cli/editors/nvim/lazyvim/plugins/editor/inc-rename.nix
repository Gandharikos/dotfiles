{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.inc-rename;
in
{
  options.my.lazyvim.inc-rename = {
    enable = mkEnableOption "Incremental LSP renaming based on Neovim's command-preview feature";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        inc-rename-nvim
      ];

      imports = [ "lazyvim.plugins.extras.editor.inc-rename" ];
    };
  };
}
