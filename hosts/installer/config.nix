{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    (import ../common/disko/luks-btrfs-tmpfs.nix {})
  ];
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };
  users.users.root.password = "123456";
  users.users.johnson = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    password = "123456";
  };
  # ssh-agent is used to pull my private secrets repo from github when deploying my nixos config.
  programs.ssh.startAgent = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    gnumake
    wget
    just # a command runner(replacement of gnumake in some cases)
    curl
  ];
  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
  };
  system.stateVersion = "26.05";
}
