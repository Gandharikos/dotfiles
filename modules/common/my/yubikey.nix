{
  lib,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) listOf str;
in
{
  options.my.yubikey = {
    enable = mkEnableOption "YubiKey support" // {
      default = true;
    };

    names = mkOption {
      type = listOf str;
      default = [
        "aegis" # YubiKey 5C Nano (Serial: 29642951) - Portable/Travel
        "janus" # YubiKey 5 NFC (Serial: 30805408) - Backup/Office
        "mimir" # YubiKey 5C NFC (Serial: 32226619) - Primary/Daily
      ];
      description = ''
        List of YubiKey names to use for SSH authentication.

        Serial number mappings are documented in:
        - secrets/core/keys/YUBIKEYS.md
        - secrets/core/keys/identify-yubikey.sh
      '';
      example = [
        "foo"
        "bar"
        "baz"
      ];
    };
  };
}
