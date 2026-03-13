{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkDefault;
  inherit (lib.my) isWayland;
  isWayland' = isWayland config;
  cfg = config.my.gui.system.fcitx5;
in {
  options.my.gui.system.fcitx5 = {
    enable =
      mkEnableOption "Enable fcitx5 input method"
      // {
        default = config.my.gui.enable;
      };
  };

  config = mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-fluent
          fcitx5-gtk
          fcitx5-mozc
          fcitx5-pinyin-zhwiki
          libsForQt5.fcitx5-qt
          qt6Packages.fcitx5-qt
          (fcitx5-rime.override {
            rimeDataPkgs = with pkgs; [
              rime-data
              # /run/current-system/sw/share/rime-data/
              rime-ice
              rime-zhwiki
            ];
          })
        ];
        waylandFrontend = mkDefault isWayland';
        settings = {
          inputMethod = {
            "GroupOrder" = {
              "0" = "default";
            };
            "Groups/0" = {
              "Name" = "default";
              "DefaultIM" = "rime";
              "Default Layout" = "us";
            };
            "Groups/0/Items/0" = {
              "Name" = "rime";
            };
            "Groups/0/Items/1" = {
              "Name" = "keyboard-us";
            };
          };
          globalOptions = {
            "Hotkey/TriggerKeys" = {
              "0" = "Control+F12";
            };
            "Hotkey/AltTriggerKeys" = {
              "0" = "";
            };
          };
          addons = {
            classicui.globalSection = {
              Font = "Noto Sans CJK SC 12";
              # MenuFont = "Sans Serif 12";
              # TrayFont = "Sans Serif 12";
            };
            clipboard = {
              globalSection = {
                "TriggerKey" = "";
              };
              # sections.TriggerKey = {
              #   "0" = "Control+Alt+semicolon";
              # };
            };
            notifications = {
              globalSection = {};
              sections.HiddenNotifications = {
                "0" = "fcitx-rime-deploy";
              };
            };
          }; # end of addons
        }; # end of fcitx5.settings
      };
    };
  };
}
