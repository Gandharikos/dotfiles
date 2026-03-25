{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.dap;
in
{
  options.my.lazyvim.dap = {
    enable = mkEnableOption "Debugging support";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
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

      imports = [
        "lazyvim.plugins.extras.dap.core"
        "lazyvim.plugins.extras.dap.nlua"
      ];
    };
  };
}
