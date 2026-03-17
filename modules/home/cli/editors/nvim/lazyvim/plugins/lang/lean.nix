{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.lean;
in
{
  options.my.neovim.lazyvim.lean = {
    enable = mkEnableOption "language lean";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        lean-nvim
      ];
      imports = [ "lazyvim.plugins.extras.lang.lean" ];
      extraPackages = with pkgs; [
        lean4
      ];
    };
  };
}
