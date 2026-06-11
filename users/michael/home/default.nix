{ config, inputs, ... }:
let
  noctalia = config.programs.noctalia.package;
in
{
  imports = [
    inputs.niri.homeModules.niri
    inputs.noctalia.homeModules.default
  ];

  programs = {
    ghostty.enable = true;
    google-chrome.enable = true;

    noctalia = {
      enable = true;
      systemd.enable = false;
    };

    niri = {
      enable = true;
      settings = {
        prefer-no-csd = true;
        hotkey-overlay.skip-at-startup = true;
        xwayland-satellite.enable = true;
        spawn-at-startup = [
          {
            argv = [
              "${noctalia}/bin/noctalia-shell"
              "--no-duplicate"
            ];
          }
        ];
      };
    };
  };
}
