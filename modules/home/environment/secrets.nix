{
  self,
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.strings) optionalString;
  inherit (config.my) home name;
  persist = config.my.persistence.enable;
in {
  imports = [
    inputs.sops.homeManagerModules.sops
  ];

  # User-level SOPS configuration using SSH key
  sops = {
    defaultSopsFile = "${self}/secrets/${name}/default.yaml";
    # Use persisted ssh key so secrets decrypt before SSH keys exist
    age.sshKeyPaths = ["${optionalString persist "/persist"}${home}/.ssh/id_ed25519"];
    # Keep GPG support for Yubikey when available
    # gnupg.home = "${home}/.gnupg";
  };

  # some security tools
  home.packages = with pkgs; [
    rage
    age
    sops
    rclone
    ssh-to-age
  ];
}
