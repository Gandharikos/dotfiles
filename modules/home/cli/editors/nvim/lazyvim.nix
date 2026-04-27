{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.my) relativeToConfig;
  cfg = config.my.neovim;
in
{
  imports = [ inputs.nix4lazyvim.homeModules.default ];

  config = mkIf (cfg.enable && cfg.distro == "lazyvim") {
    programs.lazyvim = {
      enable = true;
      neovim = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
      configDir = relativeToConfig "nvim";
      enableDependencies = true;

      extras = {
        ai.copilot.enable = true;
        ai.sidekick.enable = true;

        coding.mini-snippets.enable = true;
        coding.neogen.enable = true;
        coding.yanky.enable = true;
        coding.mini-surround.enable = true;

        dap.core.enable = true;

        editor.inc-rename.enable = true;
        editor.dial.enable = true;
        editor.mini-files.enable = true;
        editor.mini-diff.enable = true;
        editor.mini-move.enable = true;

        formatting.prettier.enable = true;

        test.core.enable = true;

        ui.edgy.enable = true;
        ui.smear-cursor.enable = true;
        ui.treesitter-context.enable = true;

        util.dot.enable = true;
        util.mini-hipatterns.enable = true;
        util.rest.enable = true;

        lang.lean.enable = true;
        lang.typescript.enable = true;
        lang.clangd.enable = true;
        lang.cmake.enable = true;
        lang.docker.enable = true;
        lang.go.enable = true;
        lang.json.enable = true;
        lang.yaml.enable = true;
        lang.toml.enable = true;
        lang.markdown.enable = true;
        lang.nix.enable = true;
        lang.python.enable = true;
        lang.rust.enable = true;
        lang.tailwind.enable = true;
        lang.tex.enable = true;
        lang.zig.enable = true;
        lang.r.enable = true;
        lang.typst.enable = true;

        vscode.default.enable = true;
      };

      extraPlugins = with pkgs.vimPlugins; [
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
        R-nvim
        dropbar-nvim
        scope-nvim
        obsidian-nvim
        zk-nvim
      ];
    };
  };
}
