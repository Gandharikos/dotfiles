{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum int str;
in
{
  imports = lib.my.scanPaths ./.;

  options.my.gui.desktop.idle = {
    default = mkOption {
      type = enum [
        "hypridle"
        "swayidle"
        "dank-material-shell"
        "noctalia-shell"
      ];
      default =
        if config.my.gui.desktop.shell.default == "noctalia-shell" then
          "noctalia-shell"
        else if config.my.gui.desktop.shell.default == "dank-material-shell" then
          "dank-material-shell"
        else if config.my.gui.desktop.default == "hyprland" then
          "hypridle"
        else
          "swayidle";
      description = "The idle tool to use.";
    };
    timeout = mkOption {
      type = int;
      default = 100;
      description = "Base idle timeout in seconds.";
    };
    keyboardBacklight = {
      enable = mkEnableOption "keyboard backlight idle handling" // {
        default = true;
      };
      device = mkOption {
        type = str;
        default = "dell::kbd_backlight";
        description = "Brightnessctl device name for the keyboard backlight.";
      };
    };
  };
}
