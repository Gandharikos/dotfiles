{
  config,
  lib,
  ...
}:
let
  cfg = config.my.numbat;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.numbat = {
    enable = mkEnableOption "numbat";
  };
  config = mkIf cfg.enable {
    programs.numbat = {
      enable = true;
      settings.exchange-rates.fetching-policy = "on-first-use";
    };
  };
}
