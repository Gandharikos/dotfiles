{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.python;
in
{
  options.my.lazyvim.python = {
    enable = mkEnableOption "language python";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        neotest-python
        nvim-dap-python
        venv-selector-nvim
      ];

      imports = [ "lazyvim.plugins.extras.lang.python" ];

      extraPackages = with pkgs; [
        pyright
        ruff
        basedpyright
      ];
    };
  };
}
