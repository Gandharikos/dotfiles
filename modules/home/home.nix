{ config, ... }:
let
  username = config.dot.name;
  homeDirectory = config.dot.home;
  inherit (config.dot) stateVersion;
in
{
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
}
