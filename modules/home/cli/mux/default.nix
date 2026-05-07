{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) enum bool;
in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.mux = {
    default = mkOption {
      type = enum [
        "tmux"
        "zellij"
      ];
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
