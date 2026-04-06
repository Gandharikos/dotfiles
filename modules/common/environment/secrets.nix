{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.strings) optionalString;
  persist = attrByPath [
    "my"
    "persistence"
    "enable"
  ] false config;
in
{
  sops = {
    defaultSopsFile = "${self}/secrets/services/default.yaml";
    # System-level SSH host key (for system-wide secrets access)
    age.sshKeyPaths = [ "${optionalString persist "/persist"}/etc/ssh/ssh_host_ed25519_key" ];
  };
}
