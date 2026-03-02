{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) attrsOf int literalExample;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.yubikey;
in {
  options.my.yubikey = {
    enable =
      mkEnableOption "yubikey support"
      // {
        default = true;
      };

    identifiers = mkOption {
      default = {
        janus = 30805408;
        aegis = 32226619;
        mimir = 29642951;
      };
      type = attrsOf int;
      description = "Attrset of Yubikey serial numbers. NOTE: Yubico's 'Security Key' products do not use unique serial number therefore, the scripts in this module are unable to distinguish between multiple 'Security Key' devices and instead will detect a Security Key serial number as the string \"[FIDO]\". This means you can only use a single Security Key but can still mix it with YubiKey 4 and 5 devices.";
      example = literalExample ''
        {
          foo = 12345678;
          bar = 87654321;
          baz = "[FIDO]";
        }
      '';
    };

    # type = mkOption {
    #   type = nullOr (enum [
    #     "NFC5"
    #     "nano"
    #   ]);
    #   default = null;
    #   description = "A list of devices to enable Yubikey support for";
    # };
  };

  config = mkIf cfg.enable {
    hm.my.yubikey.touchDetector.enable = isLinux;

    # TODO: need to figure out how to use gpg-agent with ssh
    # or just ues ssh-agent with yubikey?
    # can ssh-agent works with yubikey?
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    environment.systemPackages = with pkgs; [
      yubikey-manager # cli-based authenticator tool. accessed via `ykman`
      yubikey-personalization
      age-plugin-yubikey
      pam_u2f # for yubikey with sudo
    ];
  };
}
