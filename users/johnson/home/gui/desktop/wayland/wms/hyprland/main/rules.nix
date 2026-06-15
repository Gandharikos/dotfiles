{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    # workspace rules
    wayland.windowManager.hyprland.settings = {
      # layer rules
      layerrule =
        let
          toRegex =
            list:
            let
              elements = lib.concatStringsSep "|" list;
            in
            "^(${elements})$";

          lowopacity = [
            "bar"
            "calendar"
            "notifications"
            "system-menu"
          ];

          highopacity = [
            "osd"
            "logout_dialog"
          ];

          blurred = lib.concatLists [
            lowopacity
            highopacity
          ];
        in
        [
          "match:namespace ${toRegex blurred}, blur on"
          "match:namespace ${toRegex [ "bar" ]}, xray 1"
          "match:namespace ${toRegex (highopacity ++ [ "music" ])}, ignore_alpha 0.5"
          "match:namespace ${toRegex lowopacity}, ignore_alpha 0.2"
        ];

      windowrule = [
        # 1Password
        "match:title ^(1Password)$, float on"
        # Bitwarden
        "match:title ^(Bitwarden)$, float on"
        "match:class ^(Bitwarden)$, float on"
        # remove borders on floating windows
        "match:float 1, border_size 0"

        # allow tearing in games
        "match:class ^(osu!|cs2)$, immediate on"
        # start spotify in ws9
        "match:title ^(Spotify( Premium)?)$, workspace 9 silent"

        # make Firefox PiP window floating and sticky
        "match:title ^(Picture-in-Picture)$, float on"
        "match:title ^(Picture-in-Picture)$, pin on"

        # idle inhibit while watching videos
        "match:class ^(mpv|.+exe|celluloid)$, idle_inhibit focus"
        "match:class ^(firefox)$, match:title ^(.*YouTube.*)$, idle_inhibit focus"
        "match:class ^(firefox)$, idle_inhibit fullscreen"

        "match:class ^(gcr-prompter)$, dim_around on"
        "match:class ^(xdg-desktop-portal-gtk)$, dim_around on"
        "match:class ^(polkit-gnome-authentication-agent-1)$, dim_around on"

        # fix xwayland apps
        "match:xwayland 1, rounding 0"
        "match:class ^(.*jetbrains.*)$, match:title ^(Confirm Exit|Open Project|win424|win201|splash)$, center on"
        "match:class ^(.*jetbrains.*)$, match:title ^(splash)$, size 640 400"

        # opacity rules
        "match:class ^(kitty)$, opacity 0.85 0.85"
        "match:class ^(Alacritty)$, opacity 0.85 0.85"
        "match:class ^(wezterm)$, opacity 0.85 0.85"
        "match:class ^(ghostty)$, opacity 0.70 0.70"
        "match:class ^(Spotify)$, opacity 0.70 0.70"
      ];
    };
  };
}
