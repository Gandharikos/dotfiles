{
  self,
  inputs,
  pkgs,
  config,
  ...
}:
let
  inherit (config.my) name;
  inherit (config.my) homeDirectory;
in
{
  imports = [
    inputs.sops.homeManagerModules.sops
  ];

  # User-level SOPS configuration using SSH key
  sops = {
    defaultSopsFile = "${self}/secrets/${name}/default.yaml";
    # Use persisted ssh key so secrets decrypt before SSH keys exist
    age.sshKeyPaths = [ "${homeDirectory}/.ssh/id_ed25519" ];
    # Keep GPG support for Yubikey when available
    # gnupg.home = "${homeDirectory}/.gnupg";
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
