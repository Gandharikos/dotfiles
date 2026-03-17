{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib.strings) optionalString;
  persist = config.my.persistence.enable;
in
{
  sops = {
    defaultSopsFile = "${self}/secrets/services/default.yaml";
    # System-level SSH host key (for system-wide secrets access)
    age.sshKeyPaths = [ "${optionalString persist "/persist"}/etc/ssh/ssh_host_ed25519_key" ];
  };
}
