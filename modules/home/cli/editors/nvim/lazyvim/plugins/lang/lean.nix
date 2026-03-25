{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.lean;
in
{
  options.my.lazyvim.lean = {
    enable = mkEnableOption "language lean";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
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
