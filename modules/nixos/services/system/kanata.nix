{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.keyboard.kanata;
in
{
  config = mkIf cfg.enable {
    hardware.uinput.enable = true;
    services.kanata = {
      enable = true;
      keyboards.default = {
        inherit (cfg) configFile;
      };
    };
  };
}
