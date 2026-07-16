{
  self,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.dot) relativeToConfig;
  cfg = config.my.neovim;
  nvim-treesitter-cpp-tools = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-treesitter-cpp-tools";
    version = "unstable-2026-07-13";
    src = pkgs.fetchFromGitHub {
      owner = "Badhi";
      repo = "nvim-treesitter-cpp-tools";
      rev = "3343f8f693497a249823f81270a3b4f2b5f46844";
      hash = "sha256-LKzfk7vN/WSyyJR87kZV2ei8dpW3hnIBRjhHJGubQ6g=";
    };
  };
in
{
  imports = [ inputs.nix4lazyvim.homeModules.default ];

  config = mkIf (cfg.enable && cfg.distro == "lazyvim") {
    sops.secrets.github-copilot = {
      sopsFile = "${self}/secrets/${config.my.name}/github-copilot";
      path = "${config.home.homeDirectory}/.config/github-copilot/apps.json";
      mode = "0600";
      format = "binary";
    };

    programs.lazyvim = {
      enable = true;
      neovim = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
      configDir = relativeToConfig "nvim";
      enableDependencies = true;

      extras = {
        ai.copilot.enable = true;
        ai.sidekick.enable = true;

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
        R-nvim
        dropbar-nvim
        git-blame-nvim
        scope-nvim
        obsidian-nvim
        zk-nvim
        vim-wakatime
        nvim-treesitter-cpp-tools
        nvim-treesitter-parsers.cpp
      ];
    };
  };
}
