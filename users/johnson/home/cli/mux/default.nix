{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) enum bool nullOr;
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.mux = {
    default = mkOption {
      type = nullOr (enum [
        "tmux"
        "zellij"
        "herdr"
      ]);
      default = "tmux";
      description = "The terminal multiplexer to use";
    };
    autoStart = mkOption {
      type = bool;
      default = false;
      description = "Whether to start the terminal multiplexer automatically";
    };
  };
}
