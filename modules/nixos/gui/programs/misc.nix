{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.gui.desktop;
  inherit (lib.modules) mkIf;
in {
  config = mkIf cfg.enable {
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
