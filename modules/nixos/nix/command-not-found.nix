{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.programs-sqlite.nixosModules.programs-sqlite
  ];

  programs.command-not-found = {
    enable = true;
    dbPath = inputs.programs-sqlite.packages.${pkgs.stdenv.hostPlatform.system}.programs-sqlite;
  };
}
