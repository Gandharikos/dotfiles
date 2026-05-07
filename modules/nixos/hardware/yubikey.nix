{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkForce;
  cfg = config.dot.yubikey;
in
{
  config = mkIf cfg.enable {
    hardware.gpgSmartcards.enable = true;

    environment.systemPackages = [
      pkgs.yubioath-flutter
    ];

    # Yubikey required services and config. See Dr. Duh NixOS config for
    # reference
    services = {
      pcscd.enable = true;
      udev.packages = [ pkgs.yubikey-personalization ];
    };

    programs = {
      ssh.startAgent = mkForce false;

      gnupg.agent = {
        enable = mkForce true;
        enableSSHSupport = mkForce true;
      };

      # YubiKey touch detector - shows notification when YubiKey needs touch
      # Official nixpkgs module: nixos/modules/programs/yubikey-touch-detector.nix
      yubikey-touch-detector.enable = true;
    };

    security.pam = {
      u2f = {
        enable = true;
        settings = {
          cue = true; # Tells user they need to press the button
          authFile = "${config.dot.home}/.config/Yubico/u2f_keys";
        };
      };
      services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        sudo-i.u2fAuth = true;
        # Attempt to auto-unlock gnome-keyring using u2f
        # NOTE: vscode uses gnome-keyring even if we aren't using gnome, which is why it's still here
        # This doesn't work
        #gnome-keyring = {
        #  text = ''
        #    session    include                     login
        #    session optional ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
        #  '';
        #};
      };
    };
  };
}
