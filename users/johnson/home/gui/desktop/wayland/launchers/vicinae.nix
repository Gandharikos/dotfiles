{
  inputs,
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optionals;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;
  inherit (config.my.gui) desktop;

  enable = osConfig.dot.gui.desktop.wayland.enable && desktop.launcher.default == "vicinae";
  vicinae = getExe config.programs.vicinae.package;
  vicinaeCmd = [
    vicinae
    "toggle"
  ];
  vicinaeToggle = escapeShellArgs vicinaeCmd;
  extensionPackages = inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.vicinae.homeManagerModules.default ];

  config = mkIf enable {
    programs.vicinae = {
      enable = true;
      enableFirefoxIntegration = true;
      systemd.enable = true;

      settings = {
        close_on_focus_loss = true;
        consider_preedit = true;
        pop_to_root_on_close = true;
        search_files_in_root = true;
        favicon_service = "twenty";
        escape_key_behavior = "close_window";

        launcher_window = {
          opacity = 0.5;
          material = "blur";
          size = {
            width = 770;
            height = 480;
          };
          compact_mode.enabled = false;
          layer_shell = {
            enabled = true;
            keyboard_interactivity = "on_demand";
            layer = "top";
          };
        };

        providers = {
          applications.preferences = {
            launchPrefix = "uwsm app -- ";
          };
        };
      };

      extensions =
        with extensionPackages;
        [
          mullvad
          nix
          wifi-commander
        ]
        ++ optionals (osConfig.dot.gui.desktop.default == "hyprland") [
          hypr
          hypr-keybinds
          hyprland-monitors
        ]
        ++ optionals (osConfig.dot.gui.desktop.default == "niri") [
          niri
        ];
    };

    wayland.windowManager.hyprland.settings.bindd = [
      "$mod, space, Toggle App Launcher, exec, ${vicinaeToggle}"
    ];

    programs.niri.settings.binds = {
      "${desktop.modKey}+Space".action.spawn = vicinaeCmd;
    };

    home.shellAliases = optionalAttrs enable {
      launcher = vicinaeToggle;
    };
  };
}
