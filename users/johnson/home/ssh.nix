{
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (config.home) homeDirectory;
  cfg = config.my.ssh;
  yubikeys = osConfig.dot.yubikey.names;
  secretsCore = lib.dot.getFile "secrets/johnson/core";
  hasSecretsCore = builtins.pathExists secretsCore;
  regularKey = secretsCore + "/id_ed25519.pub";
  keysDir = secretsCore + "/keys";
  identifyYubikey = keysDir + "/identify-yubikey.sh";
  identityFiles =
    if cfg.enableFido2 then
      map (name: "${homeDirectory}/.ssh/id_${name}") yubikeys
    else
      [ "${homeDirectory}/.ssh/id_ed25519" ];
in
{
  config = mkIf cfg.enable (mkMerge [
    {
      my.ssh.enableFido2 = mkDefault false;

      programs.ssh.matchBlocks = {
        "*" = {
          identityFile = mkDefault identityFiles;
          addKeysToAgent = mkDefault (if cfg.enableFido2 then "no" else "yes");
        };

        "192.168.*" = {
          forwardAgent = mkDefault true;
        };

        "loki" = {
          hostname = mkDefault "loki.local";
          forwardAgent = mkDefault true;
        };

        "sigurd" = {
          hostname = mkDefault "sigurd.local";
          forwardAgent = mkDefault true;
        };

        "ymir" = {
          hostname = mkDefault "ymir.local";
          forwardAgent = mkDefault true;
        };

        "nidhogg" = {
          hostname = mkDefault "nidhogg.local";
          forwardAgent = mkDefault true;
        };

        "github.com" = {
          hostname = mkDefault "github.com";
          user = mkDefault "git";
          identityFile = mkDefault identityFiles;
          identitiesOnly = mkDefault true;
        };
      };

      home.file = lib.optionalAttrs (hasSecretsCore && builtins.pathExists regularKey) {
        ".ssh/id_ed25519.pub".source = regularKey;
      };
    }

    (mkIf cfg.enableFido2 {
      home.file = mkMerge [
        (lib.optionalAttrs (hasSecretsCore && builtins.pathExists identifyYubikey) {
          ".local/bin/identify-yubikey" = {
            source = identifyYubikey;
            executable = true;
          };
        })

        (builtins.listToAttrs (
          builtins.filter (x: x != null) (
            map (
              name:
              let
                pubKeyPath = keysDir + "/id_${name}.pub";
              in
              if hasSecretsCore && builtins.pathExists pubKeyPath then
                {
                  name = ".ssh/id_${name}.pub";
                  value.source = pubKeyPath;
                }
              else
                null
            ) yubikeys
          )
        ))
      ];
    })
  ]);
}
