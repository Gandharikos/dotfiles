{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  cfg = config.dot.services.keyd;
  kbCfg = config.dot.keyboard;
in
{
  options.dot.services.keyd = {
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
        ids = [
          "*"
          "-1234:5678" # vicinae-snippet-virtual-keyboard
        ];
        settings = {
          global = {
            chord_timeout = "30";
          };

          main = {
            capslock = "overload(control, esc)";
            tab = "overload(tab_layer, tab)";
            leftshift = "overload(shift, macro(leftshift))";
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
            "a+s" = "tab";
            "l+semicolon" = "enter";
            "o+p" = "backspace";
            "s+d" = "&";
            "d+f" = "|";
            "x+c" = "backslash";
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
            a = "ä";
            u = "ü";
            o = "ö";
            s = "ß";
          };

          shift = {
            comma = "semicolon";
            dot = ":";
            "u+i" = "<";
            "i+o" = ">";
          };

          "tab_layer+shift" = {
            # German umlauts (uppercase)
            a = "Ä";
            u = "Ü";
            o = "Ö";
            s = "ẞ";
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

    dot.users.${config.dot.primaryUser}.home.home.file.".XCompose".source =
      "${pkgs.keyd}/share/keyd/keyd.compose";
  };
}
