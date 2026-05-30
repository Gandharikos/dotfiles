{ pkgs, ... }:

{
  languages.rust = {
    enable = true;
    channel = "stable";
  };

  packages = [ pkgs.pre-commit ];
}
