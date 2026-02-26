{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.apps.vscode;
in {
  options.my.desktop.apps.vscode = {
    enable =
      mkEnableOption "Visual Studio Code"
      // {
        default = config.my.desktop.enable;
      };
  };

  config = mkIf cfg.enable {
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
          "vscode-neovim.neovimExecutablePaths.darwin" = "/etc/profiles/per-user/${config.my.name}/bin/nvim";
          # "vscode-neovim.neovimInitPath" = "~/.config/nvim/vscode/init.vim";
        };
      };
    };
  };
}
