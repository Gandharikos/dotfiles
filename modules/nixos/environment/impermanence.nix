{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.my.persistence;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) optionalString concatLines;
  inherit (lib.attrsets) attrValues;
in {
  imports = [inputs.impermanence.nixosModules.impermanence];

  config = mkIf cfg.enable {
    fileSystems."/persist".neededForBoot = true; # required by impermanence
    fileSystems."/var/log".neededForBoot = true; # required by nixos

    # There are two ways to clear the root filesystem on every boot:
    ##  1. use tmpfs for /
    ##  2. (btrfs/zfs only)take a blank snapshot of the root filesystem and revert to it on every boot via:
    # boot.initrd.postResumeCommands = lib.mkAfter ''
    #   mkdir /btrfs_tmp
    #   mount /dev/root_vg/root /btrfs_tmp
    #   if [[ -e /btrfs_tmp/root ]]; then
    #       mkdir -p /btrfs_tmp/old_roots
    #       timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
    #       mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    #   fi
    #
    #   delete_subvolume_recursively() {
    #       IFS=$'\n'
    #       for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
    #           delete_subvolume_recursively "/btrfs_tmp/$i"
    #       done
    #       btrfs subvolume delete "$1"
    #   }
    #
    #   for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
    #       delete_subvolume_recursively "$i"
    #   done
    #
    #   btrfs subvolume create /btrfs_tmp/root
    #   umount /btrfs_tmp
    # '';
    #
    #  See also https://grahamc.com/blog/erase-your-darlings/

    # NOTE: impermanence only mounts the directory/file list below to /persist
    # If the directory/file already exists in the root filesystem, you should
    # move those files/directories to /persistent first!
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/etc/nix"
        "/etc/NetworkManager/system-connections"
        "/var/db/sudo"
        # maybe we need more fine-grained
        "/var/lib"
      ];
      files = [
        # Keep machine-id management out of impermanence file binds.
        "/etc/machine-id"
        # "/etc/ssh/ssh_host_ed25519_key"
        # "/etc/ssh/ssh_host_ed25519_key.pub"
        # "/etc/ssh/ssh_host_rsa_key"
        # "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };

    # Ensure profile symlinks exist on ephemeral $HOME.
    # Home Manager activation runs from the system service on NixOS.
    environment.loginShellInit = ''
      system_profile="/etc/profiles/per-user/$USER"
      profile_link="$HOME/.local/state/nix/profiles/profile"

      if [ -e "$system_profile" ] || [ -L "$system_profile" ]; then
        mkdir -p "$(dirname "$profile_link")"
        [ -e "$profile_link" ] || ln -sfn "$system_profile" "$profile_link"
        [ -e "$HOME/.nix-profile" ] || ln -sfn "$profile_link" "$HOME/.nix-profile"
      fi
    '';

    system.activationScripts = {
      # NOTE: we use nixos-anywhere with copy-host-keys arg
      # so we need copy these ssh keys to /persist on frest installs
      persistent-ssh.text = let
        sshKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            mode = "700";
          }
          {
            path = "/etc/ssh/ssh_host_ed25519_key.pub";
            mode = "755";
          }
          {
            path = "/etc/ssh/ssh_host_rsa_key";
            mode = "700";
          }
          {
            path = "/etc/ssh/ssh_host_rsa_key.pub";
            mode = "755";
          }
        ];
        cpSSHKeys = key: let
          dest = "/persist${key.path}";
        in ''
          if [ -f "${key.path}" ]; then
            echo "Copying ${key.path} to ${dest} with mode ${key.mode}"
            mkdir -p "$(dirname "${dest}")"
            cp -a "${key.path}" "${dest}"
            chmod ${key.mode} "${dest}"
          fi
        '';
      in ''
        #!/bin/sh
        if [ ! -f /persist/etc/ssh/.init ]; then
          echo "Initializing persistent SSH keys..."
          ${lib.concatLines (map cpSSHKeys sshKeys)}
          touch /persist/etc/ssh/.init
          echo "Persistent SSH keys initialization complete."
        else
          echo "Persistent SSH keys already initialized, skipping."
        fi
      '';
      create-home.text = let
        mkHomePersist = user:
          optionalString user.createHome ''
            mkdir -p /persist${user.home}
            chown ${user.name}:${user.group} /persist${user.home}
            chmod ${user.homeMode} /persist${user.home}

            mkdir -p /persist${user.home}/.ssh
            chown ${user.name}:${user.group} /persist${user.home}/.ssh
            chmod 700 /persist${user.home}/.ssh

            mkdir -p /persist${user.home}/.gnupg
            chown ${user.name}:${user.group} /persist${user.home}/.gnupg
            chmod 700 /persist${user.home}/.gnupg
          '';
        users = attrValues config.users.users;
      in
        concatLines (map mkHomePersist users);
    };

    # for some reason *this* is what makes networkmanager not get screwed completely instead of the impermanence module
    systemd.tmpfiles.rules =
      [
        "L /var/lib/NetworkManager/secret_key - - - - /persist/var/lib/NetworkManager/secret_key"
        "L /var/lib/NetworkManager/seen-bssids - - - - /persist/var/lib/NetworkManager/seen-bssids"
        "L /var/lib/NetworkManager/timestamps - - - - /persist/var/lib/NetworkManager/timestamps"
      ]
      ++ lib.concatMap (
        user:
          lib.optionals user.createHome [
            # Keep parent directories writable for user-level Home Manager links.
            "d ${user.home}/.config 0755 ${user.name} ${user.group} - -"
            "d ${user.home}/.cache 0755 ${user.name} ${user.group} - -"
            "d ${user.home}/.local 0755 ${user.name} ${user.group} - -"
            "d ${user.home}/.local/state 0755 ${user.name} ${user.group} - -"
            "d ${user.home}/.local/state/nix 0755 ${user.name} ${user.group} - -"
            "d ${user.home}/.local/share 0755 ${user.name} ${user.group} - -"
            "d ${user.home}/.local/share/direnv 0755 ${user.name} ${user.group} - -"
            "z ${user.home}/.config 0755 ${user.name} ${user.group} - -"
            "z ${user.home}/.cache 0755 ${user.name} ${user.group} - -"
            "z ${user.home}/.local 0755 ${user.name} ${user.group} - -"
            "z ${user.home}/.local/state 0755 ${user.name} ${user.group} - -"
            "z ${user.home}/.local/state/nix 0755 ${user.name} ${user.group} - -"
            "z ${user.home}/.local/share 0755 ${user.name} ${user.group} - -"
            "z ${user.home}/.local/share/direnv 0755 ${user.name} ${user.group} - -"
          ]
      ) (attrValues config.users.users);

    environment.systemPackages = [
      # `sudo ncdu -x /`
      pkgs.ncdu
    ];

    # for uesr level persistence
    programs.fuse.userAllowOther = true;
  };
}
