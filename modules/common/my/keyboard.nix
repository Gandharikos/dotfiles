{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types)
    path
    enum
    nullOr
    bool
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

    type = mkOption {
      type = nullOr (enum [
        "kanata"
        "karabiner"
        "keyd"
      ]);
      default = null;
      description = "The keyboard remapping tool to use. null disables all remapping.";
    };

    keys = lib.genAttrs (letters ++ upperLetters) mkLetterOption;

    kanata = {
      enable = mkOption {
        type = bool;
        default = config.my.keyboard.type == "kanata";
        internal = true;
        readOnly = true;
        description = "Whether kanata is active. Controlled by my.keyboard.type.";
      };

      package = mkPackageOption pkgs "kanata-with-cmd" { };

      configFile = mkOption {
        type = path;
        default = relativeToConfig "kanata/${pkgs.stdenv.hostPlatform.parsed.kernel.name}.kbd";
        description = "Path to the primary Kanata configuration file.";
      };

      # tray.enable = mkEnableOption "kanata tray helper" // {default = cfg.enable;};
    };

    karabiner = {
      package = mkPackageOption pkgs "karabiner-elements" { };

      configFile = mkOption {
        type = path;
        default = relativeToConfig "karabiner/karabiner.json";
        description = "Path to the Karabiner-Elements configuration file.";
      };
    };

    keyd = {
      configFile = mkOption {
        type = path;
        default = relativeToConfig "keyd/default.conf";
        description = "Path to the keyd configuration file.";
      };
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
