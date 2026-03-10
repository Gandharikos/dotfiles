{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.types) listOf str;

  inherit (builtins) concatStringsSep;
  cfg = config.my.services.earlyoom;
in {
  options.my.services.earlyoom = {
    enable =
      mkEnableOption "earlyoom"
      // {
        default = config.my.gui.enable;
      };
    avoid = mkOption {
      type = listOf str;
      default = [
        "Hyprland"
        "sway"
        "Xwayland"
        "cryptsetup"
        "dbus-.*"
        "gpg-agent"
        "greetd"
        "ssh-agent"
        ".*qemu-system.*"
        "sddm"
        "sshd"
        "systemd"
        "systemd-.*"
        "wezterm"
        "kitty"
        "ghostty"
        "bash"
        "zsh"
        "fish"
        "n?vim"
      ];
      description = ''
        A list of processes to avoid killing. This is a regex that will be
        matched against the process name.
      '';
    };
    prefer = mkOption {
      type = listOf str;
      default = [
        # browsers
        "Web Content"
        "Isolated Web Co"
        "firefox.*"
        "chrom(e|ium).*"
        "electron"
        "dotnet"
        ".*.exe"
        "java.*"
        "pipewire(.*)"
        "nix"
        "npm"
        "node"
        "pipewire(.*)"
      ];
      description = ''
        A list of processes to prefer killing. This is a regex that will be
        matched against the process name.
      '';
    };
  };

  config = mkIf cfg.enable {
    # https://dataswamp.org/~solene/2022-09-28-earlyoom.html
    # avoid the linux kernel from locking itself when we're putting too much strain on the memory
    # this helps avoid having to shut down forcefully when we OOM
    services = {
      earlyoom = {
        enable = true;
        enableNotifications = true; # annoying, but we want to know what's killed

        reportInterval = 0;
        freeSwapThreshold = 5;
        freeSwapKillThreshold = 2;
        freeMemThreshold = 5;
        freeMemKillThreshold = 2;

        extraArgs = let
          avoid = concatStringsSep "|" cfg.avoid;
          prefer = concatStringsSep "|" cfg.prefer;
        in [
          "-g"
          "--avoid"
          "^(${avoid})$" # things that we want to avoid killing
          "--prefer"
          "^(${prefer})$" # things we want to remove fast
        ];

        # we should ideally write the logs into a designated log file; or even better, to the journal
        # for now we can hope this echo sends the log to somewhere we can observe later
        killHook = pkgs.writeShellScript "earlyoom-kill-hook" ''
          echo "Process $EARLYOOM_NAME ($EARLYOOM_PID) was killed"
        '';
      };
      systembus-notify.enable = mkForce true;
    };

    systemd.services.earlyoom.serviceConfig = {
      # from upstream
      DynamicUser = true;
      AmbientCapabilities = "CAP_KILL CAP_IPC_LOCK";
      Nice = -20;
      OOMScoreAdjust = -100;
      ProtectSystem = "strict";
      ProtectHome = true;
      Restart = "always";
      TasksMax = 10;
      MemoryMax = "50M";

      # Protection rules. Mostly from the `systemd-oomd` service
      # with some of them already included upstream.
      CapabilityBoundingSet = "CAP_KILL CAP_IPC_LOCK";
      PrivateDevices = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;

      PrivateNetwork = true;
      IPAddressDeny = "any";
      RestrictAddressFamilies = "AF_UNIX";

      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@resources @privileged"
      ];
    };
  };
}
