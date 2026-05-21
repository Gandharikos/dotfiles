{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.dot) enabledUsers primaryUser users;
  inherit (lib.attrsets) genAttrs;
  inherit (lib.modules) mkIf;
  cfgUser = config.users.users."${primaryUser}";
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users = {
    # Don't allow mutation of users outside the config.
    mutableUsers = false;

    # set user's default shell system-wide
    defaultUserShell = pkgs.bashInteractive;

    groups = {
      docker = { };
      wireshark = { };
      # for android platform tools's udev rules
      adbusers = { };
      dialout = { };
      # for openocd (embedded system development)
      plugdev = { };
      # misc
      uinput = { };
    }
    // genAttrs enabledUsers (_: { });
    users =
      genAttrs enabledUsers (name: {
        # we have to use initialHashedPassword here when using tmpfs for /
        inherit (config.dot.users.${name}) initialHashedPassword;
        group = "users";
        # set isNormalUser to true to create a home directory
        isNormalUser = true;
        extraGroups = ifTheyExist users.${name}.groups;
      })
      // {
        # root's ssh key are mainly used for remote deployment
        root = {
          inherit (cfgUser) initialHashedPassword;
          openssh.authorizedKeys.keys = cfgUser.openssh.authorizedKeys.keys;
        };
      };
  };

  systemd.services = mkIf config.services.userborn.enable (
    genAttrs (map (name: "home-manager-${name}") enabledUsers) (_: {
      after = [ "userborn.service" ];
      requires = [ "userborn.service" ];
    })
  );
}
