{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted;
  inherit (lib.attrsets) attrValues filterAttrs;
  inherit (lib.modules) mkIf;

  proxyHostNames = map (service: service.hostName) (
    attrValues (filterAttrs (_: service: service.localHostAlias) cfg.proxyBackends)
  );
in
{
  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = proxyHostNames;
  };
}
