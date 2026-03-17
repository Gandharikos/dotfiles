{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types)
    path
    enum
    addCheck
    str
    ;
  inherit (lib.my) relativeToConfig;
  cfg = config.my.keyboard;
  letters = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz";
  upperLetters = lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  char = addCheck str (s: builtins.stringLength s == 1);
  mkLetterOption =
    letter:
    mkOption {
      type = char;
      default = letter;
      description = "Single-letter option for ${letter}.";
    };
in
{
  options.my.keyboard = {
    # Note: I need to use general keyboard layout for my laptop and for Enterprise desktop
    layout = mkOption {
      type = enum [
        "qwerty"
        "colemak"
      ];
      default = "colemak";
      description = "The keyboard layout to use";
    };

    keys = lib.genAttrs (letters ++ upperLetters) mkLetterOption;

    kanata = {
      enable = mkEnableOption "Kanata keyboard remapping";

      package = mkPackageOption pkgs "kanata-with-cmd" { };

      configFile = mkOption {
        type = path;
        default = relativeToConfig "kanata/${pkgs.stdenv.hostPlatform.parsed.kernel.name}.kbd";
        description = "Path to the primary Kanata configuration file.";
      };

      # tray.enable = mkEnableOption "kanata tray helper" // {default = cfg.enable;};
    };
  };

  config = mkIf (cfg.layout == "colemak") {
    my.keyboard.keys = {
      h = "n";
      j = "e";
      k = "i";
      l = "o";
      H = "N";
      J = "E";
      K = "I";
      L = "O";
      n = "k";
      e = "j";
      o = "l";
      i = "h";
      N = "K";
      E = "J";
      I = "H";
      O = "L";
    };
  };
}
