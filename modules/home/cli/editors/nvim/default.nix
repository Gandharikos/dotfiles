{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim;
in
{
  imports = [ ./lazyvim ];

  options.my.neovim = {
    enable = mkEnableOption "neovim" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # Clear all caches
    # rm -rf ~/.cache/nvim/ ~/.local/share/nvim/lazy/ ~/.local/share/nvim/nvchad/
    # Clear old luac cache
    # find ~/.cache/nvim/luac -type f -mtime +1 -delete

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
