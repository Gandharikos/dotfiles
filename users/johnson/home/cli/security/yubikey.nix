{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (config.home) homeDirectory;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf osConfig.dot.yubikey.enable {
    sops.secrets.u2f_keys.path = "${homeDirectory}/.config/Yubico/u2f_keys";
  };
}
