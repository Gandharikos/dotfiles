{
  config,
  lib,
  ...
}:
let
  inherit (config.my) name theme;
  inherit (config.hm.my) gui;
  inherit (lib.modules) mkIf;
  dmsEnabled = gui.enable && gui.desktop.shell == "dnak-material-shell";
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
      "f /var/lib/AccountsService/icons/${name} 0644 root root - ${theme.avatar}"
      # Ensure the users directory exists
      "d /var/lib/AccountsService/users 0755 root root -"
      # Create a user configuration file pointing to the avatar
      "f /var/lib/AccountsService/users/${name} 0644 root root - \"[User]\\nIcon=/var/lib/AccountsService/icons/${name}\\n\""
    ];
  };
}
