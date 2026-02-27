{lib, ...}: let
  inherit (lib.modules) mkForce;
in {
  security = {
    # disable sudo as we are moving to doas
    sudo.enable = mkForce false;
    sudo-rs.enable = mkForce false;

    # https://wiki.nixos.org/wiki/Doas
    # doas is a more lightweight and secure alternative to sudo
    doas = {
      enable = true;

      # whether to create a `sudo` alias for `doas`
      # this is useful for scripts and other tools that expect `sudo`
      # however we are going to use shell aliases instead
      extraRules = [
        {
          groups = ["wheel"];
          # whether the user should be prompted for a password for every command
          noPass = false;
          # whether the user should be prompted for a password only once per session
          persist = true;
          # whether to keep the environment variables
          keepEnv = true;
        }
        # allow wheel group to execute certain commands without a password
        {
          groups = ["wheel"];
          noPass = true;
          cmd = "nixos-rebuild";
        }
        {
          groups = ["wheel"];
          noPass = true;
          cmd = "darwin-rebuild";
        }
        {
          groups = ["wheel"];
          noPass = true;
          cmd = "nix-collect-garbage";
        }
        {
          groups = ["wheel"];
          noPass = true;
          cmd = "systemctl";
        }
      ];
    };
  };

  # create a `sudo` alias for `doas` for convenience
  environment.shellAliases = {
    sudo = "doas";
  };
}
