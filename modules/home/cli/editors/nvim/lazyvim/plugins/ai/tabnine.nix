{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.tabnine;
in
{
  options.my.neovim.lazyvim.tabnine = {
    enable = mkEnableOption "AI plugin - tabnine";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins =
        with pkgs.vimPlugins;
        # let
        #   tabnine-nvim = pkgs.vimUtils.buildVimPlugin {
        #     name = "tabnine-nvim";
        #     version = "2025-04-06";
        #     src = pkgs.fetchFromGitHub {
        #       owner = "codota";
        #       repo = "tabnine-nvim";
        #       fetchSubmodules = true;
        #       rev = "4caf2e107f4cf92815f4d287c82b5897685d2875";
        #       sha256 = "15f2icqi9f4d1grcxad2j7csp8c2gbajhvjq3n6w3rqvh7k0rcf1";
        #     };
        #   };
        # in
        [
          cmp-tabnine
        ];

      imports = [ "lazyvim.plugins.extras.ai.tabnine" ];
    };
    # my.neovim.lazyvim.extraPackages = with pkgs; [
    #   tabnine
    # ];

    # xdg.configFile = mkMerge [
    #   (sourceLua "ai/tabnine.lua")
    # ];
  };
}
