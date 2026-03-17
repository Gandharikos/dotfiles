{
  config,
  pkgs,
  ...
}:
let
  inherit (config.my) name;
  cfgUser = config.users.users."${config.my.name}";
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users = {
    # Don't allow mutation of users outside the config.
    mutableUsers = false;

    # set user's default shell system-wide
    defaultUserShell = pkgs.bashInteractive;

    groups = {
      "${name}" = { };
      docker = { };
      wireshark = { };
      # for android platform tools's udev rules
      adbusers = { };
      dialout = { };
      # for openocd (embedded system development)
      plugdev = { };
      # misc
      uinput = { };
    };
    users = {
      "${name}" = {
        # we have to use initialHashedPassword here when using tmpfs for /
        inherit (config.my) initialHashedPassword;
        group = "users";
        # set isNormalUser to true to create a home directory
        isNormalUser = true;
        extraGroups = [
          # we need this to use `sudo -i`
          "wheel"
        ]
        ++ ifTheyExist [
          name
          "users"
          "git"
          "networkmanager"
          "docker"
          "wireshark"
          "adbusers"
          "libvirtd"
        ];
      };
      # root's ssh key are mainly used for remote deployment
      root = {
        inherit (cfgUser) initialHashedPassword;
        openssh.authorizedKeys.keys = cfgUser.openssh.authorizedKeys.keys;
      };
    };
  };
}
