{
  modules = [
    {
      hm.imports = [
        ./shared/nvim.nix
        ./shared/cli.nix
        ./shared/dev.nix
      ];
    }
  ];
}
