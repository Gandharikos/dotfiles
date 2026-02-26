{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.desktop.apps._1password;
in {
  options.my.desktop.apps._1password = {
    enable =
      mkEnableOption "1Password"
      // {
        default = config.my.desktop.enable && isLinux;
      };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [_1password-cli _1password-gui];
  };
}
