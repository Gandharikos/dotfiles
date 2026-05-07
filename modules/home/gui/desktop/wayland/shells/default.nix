{ lib, ... }:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum nullOr;
in
{
  imports = scanPaths ./.;

  options.my.gui.desktop.shell = {
    default = mkOption {
      type = nullOr (enum [
        "dank-material-shell"
        "noctalia-shell"
      ]);
      default = "noctalia-shell";
      description = "The desktop shell to use.";
    };
  };
}
