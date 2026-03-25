{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.my) relativeToConfig;
  cfg = config.my.lazyvim.custom;
in
{
  options.my.lazyvim.custom = {
    enable = mkEnableOption "Custom Configs";
  };

  config = mkIf cfg.enable {
    my.lazyvim.extraPlugins = with pkgs.vimPlugins; [
      {
        name = "mini.align";
        path = mini-nvim;
      }
      {
        name = "mini.operators";
        path = mini-nvim;
      }
      {
        name = "mini.bracketed";
        path = mini-nvim;
      }
      nvim-window-picker
      winshift-nvim
      treesj
      nvim-spider
      smart-splits-nvim
      diffview-nvim
      git-blame-nvim
      git-conflict-nvim
      undotree
      dropbar-nvim
      scope-nvim
      obsidian-nvim
    ];

    xdg.configFile = {
      "nvim/lua/plugins".source = relativeToConfig "nvim/lua/plugins";
      "nvim/lua/config".source = relativeToConfig "nvim/lua/config";
      "nvim/lua/util".source = relativeToConfig "nvim/lua/util";
      "nvim/snippets".source = relativeToConfig "nvim/snippets";
      "nvim/spell".source = relativeToConfig "nvim/spell";
    };
  };
}
