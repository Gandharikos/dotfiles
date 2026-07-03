{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.dot.security;
  inherit (lib) getExe';
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
in
{
  options.dot.security.privilege = mkOption {
    type = enum [
      "sudo-rs"
      "run0"
    ];
    default = "run0";
    description = "Privilege escalation backend to use.";
  };

  config = mkMerge [
    (mkIf (cfg.privilege == "sudo-rs") {
      # Use sudo-rs instead of traditional sudo (like Ubuntu 25.10)
      # https://discourse.ubuntu.com/t/adopting-sudo-rs-by-default-in-ubuntu-25-10/60583
      security.sudo-rs = {
        enable = true;

        # Wheel group can run any command, but needs password (except for specific commands below)
        wheelNeedsPassword = mkDefault false;

        # Set to true for stricter security if you don't have service users needing sudo
        execWheelOnly = mkDefault true;

        extraConfig = ''
          Defaults !lecture
          Defaults pwfeedback
          Defaults env_keep += "EDITOR PATH DISPLAY"
          Defaults timestamp_timeout = 300
        '';

        extraRules = [
          {
            groups = [ "wheel" ];
            commands = [
              # System management commands - no password needed
              {
                command = getExe' config.system.build.nixos-rebuild "nixos-rebuild";
                options = [ "NOPASSWD" ];
              }
              {
                command = getExe' pkgs.systemd "systemctl";
                options = [ "NOPASSWD" ];
              }
              {
                command = getExe' pkgs.systemd "reboot";
                options = [ "NOPASSWD" ];
              }
              {
                command = getExe' pkgs.systemd "shutdown";
                options = [ "NOPASSWD" ];
              }
              {
                command = getExe' pkgs.systemd "poweroff";
                options = [ "NOPASSWD" ];
              }

              # Nix commands - no password needed
              {
                command = getExe' pkgs.nix "nix-collect-garbage";
                options = [ "NOPASSWD" ];
              }
              {
                command = getExe' pkgs.nix "nix-store";
                options = [ "NOPASSWD" ];
              }

              # Utilities - no password needed
              {
                command = getExe' pkgs.util-linux "dmesg";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      };
    })

    (mkIf (cfg.privilege == "run0") {
      security = {
        run0 = {
          enable = true;

          # Passwordless wheel would make the sudo shim passwordless too.
          wheelNeedsPassword = false;

          # Provide sudo compatibility while keeping sudo and sudo-rs disabled.
          sudo-shim.enable = true;
        };

        sudo.enable = false;
        sudo-rs.enable = false;
      };
    })
  ];
}
