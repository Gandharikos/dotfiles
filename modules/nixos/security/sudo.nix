{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.my.security.sudo;
  inherit (lib) getExe' map;
  inherit
    (lib.modules)
    mkAfter
    mkDefault
    mkForce
    mkIf
    mkMerge
    ;
  inherit (lib.options) mkOption;
  inherit
    (lib.types)
    bool
    enum
    listOf
    package
    str
    submodule
    ;

  mkCommandPath = rule: getExe' rule.package rule.command;

  mkSudoCommand = rule: {
    command = mkCommandPath rule;
    options = ["NOPASSWD"];
  };

  mkDoasRule = rule: {
    groups = ["wheel"];
    noPass = true;
    cmd = mkCommandPath rule;
  };

  sudoCommands = map mkSudoCommand cfg.rules;
  doasCommands = map mkDoasRule cfg.rules;
in {
  options.my.security.sudo = {
    backend = mkOption {
      type = enum [
        "sudo-rs"
        "doas"
      ];
      default = "sudo-rs";
      description = ''
        Which privilege escalation backend to enable.
      '';
    };

    wheelNeedsPassword = mkOption {
      type = bool;
      default = true;
      description = ''
        Whether users of the `wheel` group must provide a password to escalate privileges.
      '';
    };

    execWheelOnly = mkOption {
      type = bool;
      default = true;
      description = ''
        Only allow members of the `wheel` group to execute `sudo-rs`.
      '';
    };

    rules = mkOption {
      type = listOf (submodule {
        options = {
          package = mkOption {
            type = package;
            description = ''
              Package providing the command to permit without a password.
            '';
          };

          command = mkOption {
            type = str;
            description = ''
              Binary name inside `package`.
            '';
          };
        };
      });
      default = with pkgs; [
        {
          package = nix;
          command = "nix-collect-garbage";
        }
        {
          package = nix;
          command = "nix-store";
        }
        {
          package = config.system.build.nixos-rebuild;
          command = "nixos-rebuild";
        }
        {
          package = systemd;
          command = "poweroff";
        }
        {
          package = systemd;
          command = "reboot";
        }
        {
          package = systemd;
          command = "shutdown";
        }
        {
          package = systemd;
          command = "systemctl";
        }
        {
          package = util-linux;
          command = "dmesg";
        }
      ];
      description = ''
        Commands that members of `wheel` may run without entering a password.
      '';
    };
  };

  config = mkMerge [
    {
      security.sudo.enable = mkForce false;
      security.sudo-rs.enable = mkForce (cfg.backend == "sudo-rs");
      security.doas.enable = mkForce (cfg.backend == "doas");
    }

    (mkIf (cfg.backend == "sudo-rs") {
      security.sudo-rs = {
        inherit (cfg) wheelNeedsPassword execWheelOnly;
        extraConfig = ''
          Defaults !lecture
          Defaults pwfeedback
          Defaults env_keep += "EDITOR PATH DISPLAY"
          Defaults timestamp_timeout = 300
        '';
        extraRules = mkAfter [
          {
            groups = ["wheel"];
            commands = sudoCommands;
          }
        ];
      };
    })

    (mkIf (cfg.backend == "doas") {
      security.doas = {
        inherit (cfg) wheelNeedsPassword;
        extraRules = mkAfter (
          [
            {
              groups = ["wheel"];
              noPass = false;
              persist = true;
              keepEnv = true;
            }
          ]
          ++ doasCommands
        );
      };
      environment.shellAliases.sudo = mkDefault "doas";
    })
  ];
}
