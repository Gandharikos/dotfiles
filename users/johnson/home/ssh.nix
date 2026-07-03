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
  inherit (cfg.gpgAgentForwarding) socketDir;
  gpgAgentSocketDir = socketDir;
  gpgAgentExtraSocket = "${gpgAgentSocketDir}/S.gpg-agent.extra";
  gpgAgentSshSocket = "${gpgAgentSocketDir}/S.gpg-agent.ssh";
  remoteGpgAgentSocket = "${gpgAgentSocketDir}/S.gpg-agent";
  gpgAgentForwardingSettings = {
    IdentityAgent = mkDefault gpgAgentSshSocket;
    RemoteForward = mkDefault "${remoteGpgAgentSocket} ${gpgAgentExtraSocket}";
  };
  gpgAgentForwardingHosts = builtins.listToAttrs (
    map (host: {
      name = host;
      value = gpgAgentForwardingSettings;
    }) cfg.gpgAgentForwarding.hosts
  );
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

      programs.ssh.settings = mkMerge [
        {
          "*" = {
            IdentityFile = mkDefault identityFiles;
            AddKeysToAgent = mkDefault (if cfg.enableFido2 then "no" else "yes");
          };

          "192.168.*" = {
            ForwardAgent = mkDefault true;
          };

          "loki" = {
            HostName = mkDefault "loki.local";
            ForwardAgent = mkDefault true;
          };

          "sigurd" = {
            HostName = mkDefault "sigurd.local";
            ForwardAgent = mkDefault true;
          };

          "ymir" = {
            HostName = mkDefault "ymir";
            Port = mkDefault 2222;
            ForwardAgent = mkDefault true;
          };

          "nidhogg" = {
            HostName = mkDefault "nidhogg.local";
            ForwardAgent = mkDefault true;
          };

          "eir" = {
            HostName = mkDefault "100.83.178.43";
            User = mkDefault "johnson";
            ForwardAgent = mkDefault true;
          };

          "athena" = {
            HostName = mkDefault "159.69.182.58";
            User = mkDefault "johnson";
            ForwardAgent = mkDefault true;
          };

          "github.com" = {
            HostName = mkDefault "github.com";
            User = mkDefault "git";
            IdentityFile = mkDefault identityFiles;
            IdentitiesOnly = mkDefault true;
          };
        }

        (mkIf cfg.gpgAgentForwarding.enable gpgAgentForwardingHosts)
      ];

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
