{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.nix;
in
{
  options.my.lazyvim.nix = {
    enable = mkEnableOption "language nix";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.nix" ];

      extraPackages = with pkgs; [
        nil
        nixfmt
      ];
    };
  };
}
