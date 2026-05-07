{
  lib,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) listOf str;
in
{
  options.dot.yubikey = {
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

        Serial number mappings are documented under the enabled user's
        secrets core directory.
      '';
      example = [
        "foo"
        "bar"
        "baz"
      ];
    };
  };
}
