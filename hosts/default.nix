{
  modules = [
    {
      hm.imports = [
        ./common/nvim.nix
        ./common/cli.nix
        ./common/dev.nix
      ];
    }
  ];
}
