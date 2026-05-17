{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.dot.persistence;
  inherit (config.dot) enabledUsers users;
  inherit (lib.attrsets) genAttrs;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption;
  mkUserPersistence =
    name:
    let
      userCfg = users.${name};
    in
    mkMerge [
      {
        inherit (userCfg.persistence) commonMountOptions;
        directories = [
          # keep-sorted start
          ".cache/fish"
          ".cache/nix"
          ".cache/nixpkgs-review"
          ".cache/pre-commit"
          ".dotfiles"
          ".local/bin"
          ".local/share/fish"
          ".local/share/nix"
          ".local/share/supermaven"
          ".local/state/home-manager"
          ".local/state/nix/profiles"
          ".pixi"
          "Desktop"
          "Dev"
          "Documents"
          "Downloads"
          "Media"
          "Misc"
          "Public"
          # keep-sorted end
          {
            directory = ".docker";
            mode = "0700";
          }
          {
            directory = ".config/sops";
            mode = "0700";
          }
          {
            directory = ".secrets";
            mode = "0700";
          }
        ];
        files = [ ];
      }
      (mkIf config.dot.gui.enable {
        directories = [
          # keep-sorted start
          ".cache/DankMaterialShell"
          ".cache/cliphist"
          ".cache/noctalia"
          ".cache/noctalia-qs"
          ".cache/quickshell"
          ".config/DankMaterialShell"
          ".config/cava"
          ".config/dgop"
          ".config/noctalia"
          ".local/share/color-schemes"
          ".local/state/DankMaterialShell"
          # keep-sorted end
        ];
      })
      (mkIf config.dot.gui._1password.enable {
        directories = [
          ".config/1Password"
        ];
      })
      (mkIf config.dot.gui.fcitx5.enable {
        directories = [
          ".config/fcitx"
          ".config/fcitx5"
          ".local/share/fcitx5"
          ".cache/fcitx5"
        ];
      })
      (mkIf config.dot.security.enable {
        directories = [
          {
            directory = ".ssh";
            mode = "0700";
          }
          {
            directory = ".local/share/password-store";
            mode = "0700";
          }
          {
            # gnome keyrings
            directory = ".local/share/keyrings";
            mode = "0700";
          }
        ];
      })
      {
        inherit (userCfg.persistence) directories;
        inherit (userCfg.persistence) files;
      }
    ];
  mkUserTmpfiles =
    name:
    let
      inherit (users.${name}) homeDirectory;
      permission = {
        user = name;
        group = lib.mkForce name;
        mode = lib.mkForce "0750";
      };
    in
    {
      "${homeDirectory}/.config".d = permission;
      "${homeDirectory}/.cache".d = permission;
      "${homeDirectory}/.local".d = permission;
      "${homeDirectory}/.local/share".d = permission;
      "${homeDirectory}/.local/state".d = permission;
      "${homeDirectory}/.local/state/nix".d = permission;
      "${homeDirectory}/.terraform.d".d = permission;
    };
in
{
  imports = [ inputs.preservation.nixosModules.default ];

  options.dot.persistence = {
    enable = mkEnableOption "persistence"; # must use tmpfs for /
  };

  config = mkIf cfg.enable {
    preservation.enable = true;

    # preservation requires initrd systemd.
    boot.initrd.systemd.enable = true;

    environment.systemPackages = [
      # `sudo ncdu -x /`
      pkgs.ncdu
    ];

    fileSystems."/persist".neededForBoot = true; # required by preservation
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

    # NOTE: preservation only mounts the directory/file list below to /persist
    # If the directory/file already exists in the root filesystem, you should
    # move those files/directories to /persistent first!
    preservation.preserveAt."/persist" = {
      # System-level directories
      directories = [
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/var/db/sudo"
        # maybe we need more fine-grained
        "/var/lib"
      ];
      files = [
        {
          # Keep machine-id management out of generic file binds.
          file = "/etc/machine-id";
          inInitrd = true;
        }
        # "/etc/ssh/ssh_host_ed25519_key"
        # "/etc/ssh/ssh_host_ed25519_key.pub"
        # "/etc/ssh/ssh_host_rsa_key"
        # "/etc/ssh/ssh_host_rsa_key.pub"
      ];

      # User-level persistence (replaces home-manager persistence module)
      users = genAttrs enabledUsers mkUserPersistence;
    };
    # Create some directories with custom permissions.
    #
    # In this configuration the path `/home/butz/.local` is not an immediate parent
    # of any persisted file so it would be created with the systemd-tmpfiles default
    # ownership `root:root` and mode `0755`. This would mean that the user `butz`
    # could not create other files or directories inside `/home/butz/.local`.
    #
    # Therefore systemd-tmpfiles is used to prepare such directories with
    # appropriate permissions.
    #
    # Note that immediate parent directories of persisted files can also be
    # configured with ownership and permissions from the `parent` settings if
    # `configureParent = true` is set for the file.
    systemd.tmpfiles.settings.preservation = mkMerge (map mkUserTmpfiles enabledUsers);

    # systemd-machine-id-commit.service would fail but it is not relevant
    # in this specific setup for a persistent machine-id so we disable it
    #
    # see the firstboot example below for an alternative approach
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    # let the service commit the transient ID to the persistent volume
    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        ""
        "/persist/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        ""
        "systemd-machine-id-setup --commit --root /persist"
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
      # so we need copy these ssh keys to /persist on fresh installs
      persistent-ssh.text =
        let
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
          cpSSHKeys =
            key:
            let
              dest = "/persist${key.path}";
            in
            ''
              if [ -f "${key.path}" ]; then
                echo "Copying ${key.path} to ${dest} with mode ${key.mode}"
                mkdir -p "$(dirname "${dest}")"
                cp -a "${key.path}" "${dest}"
                chmod ${key.mode} "${dest}"
              fi
            '';
        in
        ''
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
    };
  };
}
