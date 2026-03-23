{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.services.keyd;
  kbCfg = config.my.keyboard;
in
{
  options.my.services.keyd = {
    enable = mkOption {
      type = lib.types.bool;
      default = kbCfg.backend == "keyd";
      internal = true;
      readOnly = true;
      description = "Whether to enable keyd keyboard remapping";
    };
  };

  config = mkIf cfg.enable {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "overload(control, esc)";
            tab = "overload(tab_layer, tab)";
            leftshift = "oneshot(shift)";
            leftcontrol = "leftmeta";
            leftmeta = "leftcontrol";
            rightalt = "rightmeta";
          };

          tab_layer = {
            q = "macro(C-f12)";
            p = "print";
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            backspace = "delete";
          };
        };
      };
    };

    # Palm rejection fix for keyd virtual keyboard
    environment.etc."libinput/local-overrides.quirks".text = ''
      [Serial Keyboards]
      MatchUdevType=keyboard
      MatchName=keyd virtual keyboard
      AttrKeyboardIntegration=internal
    '';
  };
}
