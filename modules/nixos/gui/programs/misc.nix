{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.my) gui;
  inherit (lib.modules) mkIf;
in {
  config = mkIf gui.enable {
    environment.systemPackages = with pkgs; [
      android-tools
    ];

    programs = {
      # dconf is a low-level configuration system.
      # we neet it to interact with gtk
      dconf.enable = true;

      # gnome's keyring manager
      seahorse.enable = true;

      # show network usage
      bandwhich.enable = true;
    };
  };
}
