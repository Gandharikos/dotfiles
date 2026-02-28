{lib, ...}: let
  inherit (lib) mkForce;
in {
  environment = {
    # disable stub-ld, this exists to kill dynamically linked executables, since they cannot work
    # on NixOS, however we know that so we don't need to see the warning
    stub-ld.enable = false;

    # disable all packages installed by default, i prefer my own packages
    # this list normally includes things like perl
    defaultPackages = mkForce [];
  };

  programs.nano.enable = false;

  # this can allow us to save some storage space
  fonts.fontDir.decompressFonts = true;
}
