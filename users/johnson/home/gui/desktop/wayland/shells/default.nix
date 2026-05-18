{
  lib,
  osConfig,
  ...
}:
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
      default = osConfig.dot.gui.desktop.shell;
      description = "The desktop shell to use.";
    };
  };
}
