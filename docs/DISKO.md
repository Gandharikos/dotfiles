# Declarative Disk Management

## install

1. run:
   `curl https://raw.githubusercontent.com/<username>/<repo>/<branch>/path/to/disko-config.nix -o /tmp/disko.nix`
   for install the disko config file from github repository.

2. run:
   `nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko`
   for declare the disk partition and mounting

3. run: `mount | grep /mnt` for check the mount points

4. you can use your yubikey to decrypt the luks partition. run:
   `sudo systemd-cryptenroll --fido2-device=auto /dev/<device>`

5. run: `nixos-generate-config --root /mnt --no-filesystems` to generate nixos configuration files
   without filesystem configuration (disko.nix holds the filesystem). and run
   `mv /tmp/disko.nix /mnt/etc/nixos/`

6. edit /etc/nixos/configuration.nix:

```nix
imports =
 [ # Include the results of the hardware scan.
   ./hardware-configuration.nix
   "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
   ./disk-config.nix
 ];
```

and grub config

```nix
boot.loader.grub.device = "nodev";
boot.loader.grub.enable = true;
boot.loader.grub.efiSupport = true;
boot.loader.grub.efiInstallAsRemovable = true;
```

6. run `nixos-install --root /mnt --no-root-password`
