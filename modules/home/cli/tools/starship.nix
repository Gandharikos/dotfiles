{
  lib,
  config,
  ...
}:
let
  cfg = config.my.starship;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.starship = {
    enable = mkEnableOption "starship";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableTransience = true;
    };
  };
}
