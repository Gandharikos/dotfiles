{
  inputs,
  pkgs,
  ...
}: {
  programs.command-not-found = {
    enable = true;
    dbPath = inputs.programs-sqlite.packages.${pkgs.stdenv.hostPlatform.system}.programs-sqlite;
  };
}
