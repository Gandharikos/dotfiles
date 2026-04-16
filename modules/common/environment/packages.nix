{
  lib,
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [
      # keep-sorted start
      cmake
      coreutils
      curl
      git
      git-lfs
      gnumake
      just # use Justfile to simplify nix-darwin's commands
      neovim
      rsync
      uutils-coreutils-noprefix
      wget
      # keep-sorted end
    ]
    ++ lib.optionals config.my.yubikey.enable [
      yubikey-manager # CLI-based authenticator tool, accessed via `ykman`
      yubikey-personalization
      age-plugin-yubikey
      pam_u2f # For YubiKey with sudo
    ];
}
