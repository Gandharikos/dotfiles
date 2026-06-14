{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.samba;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.selfhosted.services.samba.enable = mkEnableOption "Samba for self-hosted file shares";

  # TODO: completed this
  # check this url: https://github.com/skogsbrus/os/blob/02e9b05a01da428df9a10588c83687f6f7bfb22b/sys/samba_server.nix#L51

  config = mkIf cfg.enable {
    services = {
      samba = {
        package = pkgs.samba4Full;
        # ^^ `samba4Full` is compiled with avahi, ldap, AD etc support (compared to the default package, `samba`
        # Required for samba to register mDNS records for auto discovery
        # See https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/pkgs/top-level/all-packages.nix#L27268
        enable = true;
        openFirewall = true;
        settings.testshare = {
          path = "/path/to/share";
          writable = "true";
          comment = "Hello World!";
        };
        # extraConfig = ''
        #   server smb encrypt = required
        #   # ^^ Note: Breaks `smbclient -L <ip/host> -U%` by default, might require the client to set `client min protocol`?
        #   server min protocol = SMB3_00
        # '';
      };
      avahi = {
        # Allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
        publish.enable = true;
        publish.userServices = true;
        openFirewall = true;
      };
      samba-wsdd = {
        # Enables autodiscovery on windows since SMB1 (and thus netbios) support was discontinued
        enable = true;
        openFirewall = true;
      };
    };
  };
}
