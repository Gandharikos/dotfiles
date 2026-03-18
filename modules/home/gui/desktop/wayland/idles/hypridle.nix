{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.lists) optionals;
  inherit (lib.meta) getExe getExe';
  inherit (lib.my) uwsmApp uwsmScript;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;

  inherit (config.my.gui) desktop;
  cfg = desktop.idle;

  app =
    exe: args: if desktop.uwsm.enable then uwsmApp pkgs exe args else escapeShellArgs ([ exe ] ++ args);

  suspendScript =
    if desktop.uwsm.enable then
      uwsmScript pkgs "suspend-script" ''
        # check if any player has statutes "Playing"
        ${getExe pkgs.playerctl} -a status | ${getExe pkgs.ripgrep} Playing -q
        # only suspend if nothing is playing
        if [ $? == 1 ]; then
          ${getExe' pkgs.systemd "systemctl"} suspend
        fi
      ''
    else
      (pkgs.writeShellScript "suspend-script" ''
        # check if any player has statutes "Playing"
        ${getExe pkgs.playerctl} -a status | ${getExe pkgs.ripgrep} Playing -q
        # only suspend if nothing is playing
        if [ $? == 1 ]; then
          ${getExe' pkgs.systemd "systemctl"} suspend
        fi
      '').outPath;

  loginctl' = getExe' pkgs.systemd "loginctl";
  brightnessctl' = getExe pkgs.brightnessctl;
  hyprctl' = getExe' pkgs.hyprland "hyprctl";
  niri' = getExe' pkgs.niri "niri";
  dimScreen =
    if desktop.uwsm.enable then
      uwsmScript pkgs "hypridle-dim-screen" ''
        ${getExe pkgs.brillo} -O
        ${getExe pkgs.brillo} -u 1000000 -S 10
      ''
    else
      "${getExe pkgs.brillo} -O; ${getExe pkgs.brillo} -u 1000000 -S 10";
  restoreScreen = app (getExe pkgs.brillo) [
    "-I"
    "-u"
    "500000"
  ];

  inherit (cfg) timeout;

  enable = desktop.idle.default == "hypridle" && desktop.wayland.enable;
  dmsPkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dms = getExe' dmsPkg "dms";
  noctaliaQsPkg = inputs.noctalia-qs.packages.${pkgs.stdenv.hostPlatform.system}.default;
  qs' = getExe' noctaliaQsPkg "qs";
  lock_cmd =
    if desktop.shell.default == "noctalia-shell" then
      app qs' [
        "-c"
        "noctalia-shell"
        "ipc"
        "call"
        "lockScreen"
        "lock"
      ]
    else if desktop.shell.default == "dank-material-shell" then
      app dms [
        "ipc"
        "call"
        "lock"
        "lock"
      ]
    else
      app loginctl' [ "lock-session" ];
  # to avoid having to press a key twice to turn on the display
  screen_on_cmd =
    if desktop.default == "hyprland" then
      app hyprctl' [
        "dispatch"
        "dpms"
        "on"
      ]
    else if desktop.default == "niri" then
      app niri' [
        "msg"
        "action"
        "power-on-monitors"
      ]
    else
      null;
  screen_off_cmd =
    if desktop.default == "hyprland" then
      app hyprctl' [
        "dispatch"
        "dpms"
        "off"
      ]
    else if desktop.default == "niri" then
      app niri' [
        "msg"
        "action"
        "power-off-monitors"
      ]
    else
      null;
in
{
  config = mkIf enable {
    home.shellAliases.caffeinate = "systemctl --user stop hypridle";

    services.hypridle = {
      enable = true;

      settings = {
        general = {
          inherit lock_cmd;

          # lock before suspend
          before_sleep_cmd = app loginctl' [ "lock-session" ];

          after_sleep_cmd = screen_on_cmd;
        };

        listener = [
          {
            timeout = timeout - 10;
            # save the current brightness and dim the screen over a period of
            # 1 second
            on-timeout = dimScreen;
            # brighten the screen over a period of 500ms to the saved value
            on-resume = restoreScreen;
          }
        ]
        ++ optionals cfg.keyboardBacklight.enable [
          {
            timeout = timeout / 2;
            on-timeout = app brightnessctl' [
              "-sd"
              cfg.keyboardBacklight.device
              "set"
              "0"
            ];
            on-resume = app brightnessctl' [
              "-rd"
              cfg.keyboardBacklight.device
            ];
          }
        ]
        ++ [
          {
            inherit timeout;
            on-timeout = app loginctl' [ "lock-session" ];
          }
          {
            inherit timeout;
            on-timeout = screen_off_cmd;
            on-resume = screen_on_cmd;
          }
          {
            timeout = timeout + 10;
            on-timeout = suspendScript;
          }
        ];
      };
    };
  };
}
