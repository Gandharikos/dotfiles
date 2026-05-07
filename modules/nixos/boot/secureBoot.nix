{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkForce mkDefault;
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.boot;
in
{
  # How to enter setup mode - msi motherboard
  ## 1. enter BIOS via [Del] Key
  ## 2. <Advance mode> => <Settings> => <Security> => <Secure Boot>
  ## 3. enable <Secure Boot>
  ## 4. set <Secure Boot Mode> to <Custom>
  ## 5. enter <Key Management>
  ## 6. select <Delete All Secure Boot Variables>, and then select <No> for <Reboot Without Saving>
  ## 7. Press F10 to saving and reboot.
  # more details: https://wiki.nixos.org/wiki/Secure_Boot
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  options.dot.boot.secureBoot = mkEnableOption "secure boot";

  config = mkIf cfg.secureBoot {
    dot.boot.loader = mkForce "none";

    environment.systemPackages = [
      # For debugging and troubleshooting Secure Boot.
      pkgs.sbctl
    ];

    boot = {
      loader = {
        # Lanzaboote currently replaces the systemd-boot module.
        # This setting is usually set to true in configuration.nix
        # generated at installation time. So we force it to false
        # for now.
        systemd-boot.enable = mkForce false;
      };
      lanzaboote = {
        enable = true;
        pkiBundle = mkDefault "/var/lib/sbctl";
      };
    };
  };
}
