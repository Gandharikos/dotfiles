{
  config,
  lib,
  ...
}:
let
  inherit (config.my) name theme;
  inherit (config.hm.my.gui) desktop;
  inherit (lib.modules) mkIf;
  dmsEnabled = desktop.wayland.enable && desktop.shell.default == "dank-material-shell";
in
{
  # INFO: I don't want use this, but dms require it.
  config = mkIf dmsEnabled {
    services.accounts-daemon.enable = true;
    # Declaratively set up the avatar and user configuration
    systemd.tmpfiles.rules = [
      # Ensure the icons directory exists
      "d /var/lib/AccountsService/icons 0755 root root -"
      # Place the avatar image in the correct location
      "L+ /var/lib/AccountsService/icons/${name} - - - - ${theme.avatar}"
    ];

    # Create the user configuration file for AccountsService
    environment.etc."AccountsService/users/${name}".text = ''
      [User]
      Icon=/var/lib/AccountsService/icons/${name}
    '';
  };
}
