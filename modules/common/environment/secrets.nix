{
  config,
  lib,
  ...
}:
let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.strings) optionalString;
  persist = attrByPath [
    "dot"
    "persistence"
    "enable"
  ] false config;
in
{
  sops = {
    # System-level SSH host key (for system-wide secrets access)
    age.sshKeyPaths = [ "${optionalString persist "/persist"}/etc/ssh/ssh_host_ed25519_key" ];
  };
}
