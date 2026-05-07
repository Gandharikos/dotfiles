{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  userOptions = lib.dot.mkUserOptions {
    inherit (pkgs.stdenv.hostPlatform) isLinux;
    config = config.my;
    inferName = false;
    name = "my";
  };
  username = config.my.name;
  homeDirectory = config.my.home;
  inherit (osConfig.dot) stateVersion;
in
{
  options.my = userOptions;

  config = {
    news.display = "show";

    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    home = {
      inherit username homeDirectory stateVersion;
      sessionPath = [
        "$HOME/.local/bin"
        "/opt/homebrew/bin"
      ];
    };

    programs.home-manager.enable = true;
  };
}
