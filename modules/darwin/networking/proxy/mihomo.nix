{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  configDir = "${config.dot.admin.homeDirectory}/.config/mihomo";
in
{
  config = lib.mkIf (cfg.enable && cfg.backend == "mihomo") {
    environment.systemPackages = [ pkgs.mihomo ];

    # Like the Darwin sing-box backend, provide the CLI/config without auto-launching a TUN.
    system.activationScripts.postActivation.text = lib.mkAfter ''
      install -d -m 0700 -o ${lib.escapeShellArg config.dot.primaryUser} -g staff \
        ${lib.escapeShellArg configDir}
    '';
  };
}
