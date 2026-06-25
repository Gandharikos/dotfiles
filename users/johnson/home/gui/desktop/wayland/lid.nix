{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.strings) escapeShellArgs;
  inherit (lib.types) str;

  cfg = config.my.gui.desktop.lid;
  isLaptop = osConfig.dot.device.type == "laptop";
  isWayland = osConfig.dot.gui.desktop.wayland.enable;

  screenOffCmd =
    if osConfig.dot.gui.desktop.default == "hyprland" then
      escapeShellArgs [
        (getExe' pkgs.hyprland "hyprctl")
        "dispatch"
        "dpms"
        "off"
      ]
    else if osConfig.dot.gui.desktop.default == "niri" then
      escapeShellArgs [
        (getExe' pkgs.niri "niri")
        "msg"
        "action"
        "power-off-monitors"
      ]
    else
      "";

  screenOnCmd =
    if osConfig.dot.gui.desktop.default == "hyprland" then
      escapeShellArgs [
        (getExe' pkgs.hyprland "hyprctl")
        "dispatch"
        "dpms"
        "on"
      ]
    else if osConfig.dot.gui.desktop.default == "niri" then
      escapeShellArgs [
        (getExe' pkgs.niri "niri")
        "msg"
        "action"
        "power-on-monitors"
      ]
    else
      "";

  lidWatch = pkgs.writeShellApplication {
    name = "lid-watch";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      read_lid_state() {
        for state_file in /proc/acpi/button/lid/*/state; do
          [ -r "$state_file" ] || continue
          case "$(cat "$state_file")" in
            *closed*)
              printf 'closed\n'
              return 0
              ;;
            *open*)
              printf 'open\n'
              return 0
              ;;
          esac
        done

        printf 'unknown\n'
      }

      screen_off() {
        ${if screenOffCmd != "" then "${screenOffCmd} >/dev/null 2>&1 || true" else ":"}
      }

      screen_on() {
        ${if screenOnCmd != "" then "${screenOnCmd} >/dev/null 2>&1 || true" else ":"}
      }

      last_state=""
      while true; do
        state="$(read_lid_state)"
        if [ "$state" != "$last_state" ]; then
          case "$state" in
            closed)
              screen_off
              ;;
            open)
              screen_on
              ;;
          esac
          last_state="$state"
        fi

        sleep 1
      done
    '';
  };

  lid = pkgs.writeShellApplication {
    name = "lid";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
      pkgs.systemd
    ];
    text = ''
      set -euo pipefail

      state_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      pid_file="$state_dir/lid.pid"
      legacy_pid_file="$state_dir/lid-toggle.pid"
      unit_name="lid-mode.service"
      why="Keep this laptop reachable over Tailscale while the lid is closed"

      usage() {
        printf 'Usage: lid [on|off|toggle|status]\n'
      }

      running_pid_from() {
        pid_file_to_check="$1"
        [ -r "$pid_file_to_check" ] || return 1

        pid="$(cat "$pid_file_to_check")"
        case "$pid" in
          "" | *[!0-9]*)
            return 1
            ;;
        esac

        kill -0 "$pid" 2>/dev/null || return 1
        args="$(ps -p "$pid" -o args= 2>/dev/null || true)"
        case "$args" in
          *systemd-inhibit*lid*)
            printf '%s\n' "$pid"
            ;;
          *)
            return 1
            ;;
        esac
      }

      running_pid() {
        running_pid_from "$pid_file" || running_pid_from "$legacy_pid_file"
      }

      is_active() {
        systemctl --user is-active --quiet "$unit_name"
      }

      stop_legacy_pid() {
        if pid="$(running_pid)"; then
          kill "$pid" 2>/dev/null || true
        fi
        rm -f "$pid_file" "$legacy_pid_file"
      }

      status() {
        if is_active; then
          main_pid="$(systemctl --user show "$unit_name" --property=MainPID --value 2>/dev/null || true)"
          printf 'on: lid mode is active (pid %s); closed lid powers monitors off, open lid powers them on, sleep stays inhibited\n' "''${main_pid:-unknown}"
        else
          printf 'off: normal lid/sleep behavior is active\n'
        fi
      }

      start() {
        stop_legacy_pid

        if is_active; then
          main_pid="$(systemctl --user show "$unit_name" --property=MainPID --value 2>/dev/null || true)"
          printf 'already on: lid mode is active (pid %s)\n' "''${main_pid:-unknown}"
          exit 0
        fi

        systemd-run --user --quiet --unit="$unit_name" --description="$why" \
          systemd-inhibit \
            --what=sleep:handle-lid-switch \
            --mode=block \
            --who=lid \
            --why="$why" \
            ${getExe lidWatch}

        sleep 0.2

        if ! is_active; then
          printf 'failed: could not start %s\n' "$unit_name" >&2
          systemctl --user status "$unit_name" --no-pager >&2 || true
          exit 1
        fi

        printf 'on: lid mode active; close lid powers monitors off, open lid powers them on, Tailscale/SSH should stay reachable\n'
      }

      stop() {
        stop_legacy_pid

        if is_active; then
          systemctl --user stop "$unit_name"
          ${if screenOnCmd != "" then "${screenOnCmd} >/dev/null 2>&1 || true" else ":"}
          printf 'off: normal lid/sleep behavior restored\n'
        else
          printf 'already off: normal lid/sleep behavior is active\n'
        fi
      }

      case "''${1:-toggle}" in
        on)
          start
          ;;
        off)
          stop
          ;;
        toggle)
          if is_active; then
            stop
          else
            start
          fi
          ;;
        status)
          status
          ;;
        -h | --help | help)
          usage
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  options.my.gui.desktop.lid = {
    enable = mkEnableOption "lid mode for keeping a laptop reachable while closed" // {
      default = isWayland && isLaptop;
    };

    command = mkOption {
      type = str;
      readOnly = true;
      default = getExe lid;
      description = "Path to the lid helper command.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ lid ];
  };
}
