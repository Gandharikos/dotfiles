{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.bitwarden-cli;
in
{
  options.my.bitwarden-cli = {
    enable = mkEnableOption "bitwarden-cli";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden-cli
    ];
  };
}
