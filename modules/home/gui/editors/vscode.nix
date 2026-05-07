{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.vscode;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.vscode = {
    enable = mkEnableOption "Visual Studio Code" // {
      default = true;
    };
  };

  config = mkIf enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          ms-python.python
          # ms-vscode.cpptools
          ms-toolsai.jupyter
          ms-azuretools.vscode-docker
          oderwat.indent-rainbow
          esbenp.prettier-vscode
          vscodevim.vim
          arrterian.nix-env-selector
          denoland.vscode-deno
          ms-vscode.cmake-tools
          llvm-vs-code-extensions.vscode-clangd
          github.copilot
          rust-lang.rust-analyzer
          golang.go
          asvetliakov.vscode-neovim
          davidanson.vscode-markdownlint
        ];
        userSettings = {
          "vscode-neovim.neovimExecutablePaths.darwin" = "/etc/profiles/per-user/${config.dot.name}/bin/nvim";
          # "vscode-neovim.neovimInitPath" = "~/.config/nvim/vscode/init.vim";
        };
      };
    };
  };
}
