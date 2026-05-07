{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.nix-your-shell;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.dot.nix-your-shell = {
    enable = mkEnableOption "nix-your-shell";
  };

  config = mkIf cfg.enable {
    programs.nix-your-shell = {
      enable = true;
    };
  };
}
