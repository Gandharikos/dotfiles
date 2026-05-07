{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr enum;
  inherit (lib.modules) mkIf;
  cfg = config.dot.neovim;
in
{
  imports = [ ./lazyvim.nix ];

  options.dot.neovim = {
    enable = mkEnableOption "neovim" // {
      default = true;
    };

    distro = mkOption {
      type = nullOr (enum [ "lazyvim" ]);
      default = "lazyvim";
      description = "The Neovim distribution to use";
    };
  };

  config = mkIf (cfg.enable && cfg.distro == null) {
    programs.neovim = {
      enable = true;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

      withNodeJs = false;
      withRuby = false;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
  };
}
