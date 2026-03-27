{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.services.kanata;
  kanataConfig =
    (import ../../../common/my/keyboard/kanata.nix { inherit lib pkgs; }).mkKanataConfig
      {
        includeDefCfg = false;
      };
in
{
  config = mkIf cfg.enable {
    hardware.uinput.enable = true;
    services.kanata = {
      enable = true;
      package = pkgs.kanata-with-cmd;
      keyboards.default = {
        config = kanataConfig;
        extraDefCfg = ''
          process-unmapped-keys yes
        '';
      };
    };
  };
}
