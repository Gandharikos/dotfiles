{ lib, ... }:
let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum nullOr;
in
{
  imports = scanPaths ./.;

  options.my.gui.desktop.shell = {
    default = mkOption {
      type = nullOr (enum [
        "dms"
        "noctalia-shell"
      ]);
      default = "dms";
      description = "The desktop shell to use.";
    };
  };
}
