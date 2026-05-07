{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.numbat;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.dot.numbat = {
    enable = mkEnableOption "numbat";
  };
  config = mkIf cfg.enable {
    programs.numbat = {
      enable = true;
      settings.exchange-rates.fetching-policy = "on-first-use";
    };
  };
}
