{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.inc-rename;
in
{
  options.my.neovim.lazyvim.inc-rename = {
    enable = mkEnableOption "Incremental LSP renaming based on Neovim's command-preview feature";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        inc-rename-nvim
      ];

      imports = [ "lazyvim.plugins.extras.editor.inc-rename" ];
    };
  };
}
