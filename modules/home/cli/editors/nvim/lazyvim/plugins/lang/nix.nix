{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.nix;
in
{
  options.my.neovim.lazyvim.nix = {
    enable = mkEnableOption "language nix";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPackages = with pkgs; [
        nil
        nixfmt
      ];
      # my.neovim.lazyvim.extraSpec = ''
      #   { import = "lazyvim.plugins.extras.lang.nix" },
      # '';
      config = [ "lang/nix.lua" ];
    };
  };
}
