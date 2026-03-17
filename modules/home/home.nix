{ config, ... }:
let
  username = config.my.name;
  homeDirectory = config.my.home;
  inherit (config.my) stateVersion;
in
{
  imports = [
    # common options defined both user level and system level
    ../common/my
  ];

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
