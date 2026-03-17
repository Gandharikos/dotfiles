{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.dap;
in
{
  options.my.neovim.lazyvim.dap = {
    enable = mkEnableOption "Debugging support";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        nvim-dap
        nvim-dap-ui
        nvim-dap-virtual-text
        nvim-nio
        one-small-step-for-vimkind
      ];

      # disable mason-nvim-dap.nvim
      extraSpec = ''
        { "jay-babu/mason-nvim-dap.nvim", enabled = false },
      '';

      config = [ "editor/dap.lua" ];
    };
  };
}
