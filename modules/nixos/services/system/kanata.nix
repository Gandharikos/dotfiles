{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  cfg = config.dot.services.kanata;
  kanataConfig =
    (import ../../../common/dot/keyboard/kanata.nix { inherit lib pkgs; }).mkKanataConfig
      { linuxDevices = cfg.keyboardDevices; };
in
{
  options.dot.services.kanata.keyboardDevices = mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Keyboard device paths under /dev/input/by-id or /dev/input/by-path.
      An empty list automatically selects keyboards, excluding Vicinae's virtual keyboard.
      Set dot.keyboard.backend to null to disable Kanata.
    '';
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(builtins.elem "*" cfg.keyboardDevices);
        message = "Use an empty dot.services.kanata.keyboardDevices list for automatic detection instead of *";
      }
    ];

    hardware.uinput.enable = true;
    services.kanata = {
      enable = true;
      package = pkgs.kanata-with-cmd;
      keyboards.default = {
        configFile = pkgs.writeText "kanata.kbd" kanataConfig;
      };
    };
  };
}
