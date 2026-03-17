{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (config.my) name;
  inherit (lib) optionals;
  cfg = config.my.neovim.lazyvim.copilot;
  inherit (config.home) homeDirectory;
in
{
  options.my.neovim.lazyvim.copilot = {
    lua.enable = mkEnableOption "AI plugin - Copilot and Copilot-Chat";
    native.enable = mkEnableOption "Using native Copilot or using copilot.lua";
    chat.enable = mkEnableOption "AI plugin - Copilot-Chat";
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = !(cfg.lua.enable && cfg.native.enable);
          message = "Copilot: choose either copilot.lua (copilot.enable) OR native LSP (copilot.native.enable), not both.";
        }
      ];
    }

    (mkIf (cfg.lua.enable || cfg.native.enable || cfg.chat.enable) {
      my.neovim.lazyvim.extraPackages = with pkgs; [ nodejs_24 ];

      sops.secrets.github-copilot = {
        sopsFile = "${self}/secrets/${name}/github-copilot";
        path = "${homeDirectory}/.config/github-copilot/apps.json";
        mode = "0400";
        format = "binary";
      };
    })
    (mkIf cfg.lua.enable {
      my.neovim.lazyvim = {
        imports = [ "lazyvim.plugins.extras.ai.copilot" ];
        extraPlugins =
          with pkgs.vimPlugins;
          [ copilot-lua ]
          ++ optionals (config.my.neovim.lazyvim.cmp == "nvim-cmp") [ copilot-cmp ]
          ++ optionals (config.my.neovim.lazyvim.cmp == "blink" || config.my.neovim.lazyvim.cmp == "auto") [
            blink-cmp-copilot
          ];
      };
    })
    (mkIf cfg.chat.enable {
      my.neovim.lazyvim = {
        imports = [ "lazyvim.plugins.extras.ai.copilot-chat" ];
        extraPlugins = with pkgs.vimPlugins; [ CopilotChat-nvim ];
      };
    })
    (mkIf cfg.native.enable {
      my.neovim.lazyvim = {
        imports = [ "lazyvim.plugins.extras.ai.copilot-native" ];
        extraPackages = with pkgs; [ copilot-language-server ];
      };
    })
  ];
}
