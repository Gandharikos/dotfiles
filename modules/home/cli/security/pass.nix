{
  pkgs,
  config,
  lib,
  ...
}:
let
  passwordStoreDir = "${config.xdg.dataHome}/password-store";
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) str;
  cfg = config.dot.security;
in
{
  options.dot.security.gpg = {
    encrytionKey = mkOption {
      type = str;
      default = "6E714D9B24EF3018DB51E7892BE66A4F9E095541";
      description = "The encrytion key of my gpg.";
    };
    signatureKey = mkOption {
      type = str;
      default = "EC571D2B91912D528A9F3B00639746C15BE596AF";
      description = "The signature key of my gpg.";
    };
  };
  config = mkIf cfg.enable {
    programs = {
      password-store = {
        enable = true;
        package = pkgs.pass.withExtensions (exts: [
          # support for one-time-password (OTP) tokens
          # NOTE: Saving the password and OTP together runs counter to the purpose of secondary verification!
          exts.pass-otp

          # exts.pass-import # a generic importer tool from other password managers
          exts.pass-update # an easy flow for updating passwords
        ]);
        # See the “Environment variables” section of pass(1) and the extension man pages for more information about the available keys.
        settings = {
          PASSWORD_STORE_DIR = passwordStoreDir;
          # Overrides the default gpg key identification set by init.
          # Hexadecimal key signature is recommended.
          # Multiple keys may be specified separated by spaces.
          PASSWORD_STORE_KEY = lib.strings.concatStringsSep " " [
            cfg.gpg.encrytionKey # E
          ];
          # all .gpg-id files and non-system extension files must be signed using a detached signature using the GPG key specified by
          #   the full 40 character upper-case fingerprint in this variable.
          # If multiple fingerprints are specified, each separated by a whitespace character, then signatures must match at least one.
          # The init command will keep signatures of .gpg-id files up to date.
          PASSWORD_STORE_SIGNING_KEY = lib.strings.concatStringsSep " " [
            cfg.gpg.signatureKey # S
          ];
          PASSWORD_STORE_CLIP_TIME = "60";
          PASSWORD_STORE_GENERATED_LENGTH = "15";
          PASSWORD_STORE_ENABLE_EXTENSIONS = "true";
        };
      };

      # password-store extensions for browsers
      # you need to install the browser extension for this to work
      # https://github.com/browserpass/browserpass-extension
      browserpass = {
        enable = true;
        browsers = [
          "chrome"
          "chromium"
          "firefox"
        ];
      };
    };
  };
}
