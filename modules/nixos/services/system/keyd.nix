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
            leftshift = "layer(shift)";
            leftcontrol = "layer(meta)";
            leftmeta = "layer(control)";
            rightalt = "rightmeta";
            ";" = "apostrophe";
            "'" = "semicolon";
            "u+i" = "(";
            "i+o" = ")";
            "w+e" = "[";
            "e+r" = "]";
            "m+comma" = "_";
            "comma+dot" = "=";
            "j+k" = "-";
            "k+l" = "+";
            "q+a" = "!";
            "w+s" = "@";
            "e+d" = "#";
            "r+f" = "$";
            "t+g" = "%";
            "y+h" = "^";
            "u+j" = "&";
            "i+k" = "*";
            "o+l" = "grave";
            "p+semicolon" = "backslash";
            "q+w" = "esc";
            "s+d" = "&";
            "d+f" = "|";
            "x+c" = "\"";
            "c+v" = "!";
          };

          tab_layer = {
            q = "macro(C-f12)";
            p = "print";
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            backspace = "delete";
            # German umlauts
            a = "macro(ä)";
            u = "macro(ü)";
            o = "macro(ö)";
            s = "macro(ß)";
          };

          shift = {
            comma = "semicolon";
            dot = ":";
            "u+i" = "<";
            "i+o" = ">";
          };

          "tab_layer+shift" = {
            # German umlauts (uppercase)
            a = "macro(Ä)";
            u = "macro(Ü)";
            o = "macro(Ö)";
            s = "macro(ẞ)";
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
