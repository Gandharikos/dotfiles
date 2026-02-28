{
  config,
  lib,
  pkgs,
  ...
}: {
  my = {
    neovim = {
      enable = true;
      lazyvim = {
        enable = true;
        custom.enable = true;

        extraPlugins = lib.optionals (config.programs.dank-material-shell.enable or false) [
          pkgs.vimPlugins.base16-nvim
        ];

        # ai
        windsurf.enable = true;
        copilot.native.enable = true;
        sidekick.enable = true;
        supermaven.enable = true;
        # coding
        mini-snippets.enable = true;
        neogen.enable = true;
        yanky.enable = true;
        mini-surround.enable = true;
        # dap
        dap.enable = true;
        # editor
        inc-rename.enable = true;
        dial.enable = true;
        mini-files.enable = true;
        mini-diff.enable = true;
        mini-move.enable = true;
        # formatting
        # biome.enable = true;
        # black.enable = true;
        prettier.enable = true;
        # test
        test.enable = true;
        # ui
        edgy.enable = true;
        smear-cursor.enable = true;
        treesitter-context.enable = true;
        # utils
        dot.enable = true;
        mini-hipatterns.enable = true;
        rest.enable = true;
        obsidian.enable = true;
        # practice.enable = true;
        # lang
        lean.enable = true;
        typescript.enable = true;
        clangd.enable = true;
        cmake.enable = true;
        docker.enable = true;
        go.enable = true;
        json.enable = true;
        yaml.enable = true;
        toml.enable = true;
        markdown.enable = true;
        nix.enable = true;
        # php.enable = true;
        python.enable = true;
        rust.enable = true;
        tailwind.enable = true;
        tex.enable = true;
        zig.enable = true;
        r.enable = true;
        typst.enable = true;
        quarto.enable = true;
        # custom
        winshift.enable = true;
        window-picker.enable = true;
        vscode.enable = true;
      };
    };
  };
}
