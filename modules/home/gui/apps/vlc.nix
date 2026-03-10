{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.vlc;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in {
  options.my.gui.apps.vlc = {
    enable =
      mkEnableOption "VLC"
      // {
        default = config.my.gui.enable && isLinux;
      };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [vlc];

      persistence."/persist" = {
        directories = [".config/vlc"];
      };
    };
  };
}
