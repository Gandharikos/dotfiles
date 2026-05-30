{ pkgs, ... }:

{
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
    npm = {
      enable = true;
      install.enable = true;
    };
  };
  languages.typescript.enable = true;

  packages = [
    pkgs.eslint_d
    pkgs.prettierd
  ];
}
