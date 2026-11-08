{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (config.home) homeDirectory;
  cfg = config.my.ssh;
  inherit (cfg.gpgAgentForwarding) socketDir;
  localGpgAgentSocketDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "${homeDirectory}/.gnupg" else socketDir;
  remoteGpgAgentSocket = "${socketDir}/S.gpg-agent";
  gpgAgentForwardingSettings = {
    IdentityAgent = mkDefault "${localGpgAgentSocketDir}/S.gpg-agent.ssh";
    RemoteForward = mkDefault "${remoteGpgAgentSocket} ${localGpgAgentSocketDir}/S.gpg-agent.extra";
    ExitOnForwardFailure = mkDefault true;
    StreamLocalBindUnlink = mkDefault true;
  };
  gpgAgentForwardingHosts =
    cfg.gpgAgentForwarding.hosts
    |> map (host: {
      name = host;
      value = gpgAgentForwardingSettings;
    })
    |> builtins.listToAttrs;
in
{
  options.my.ssh = {
    enable = mkEnableOption "SSH configuration" // {
      default = osConfig.dot.security.enable;
    };

    enableFido2 = mkEnableOption "YubiKey FIDO2 SSH authentication" // {
      description = ''
        Enable YubiKey FIDO2 SSH authentication.
        When enabled: Only FIDO2 keys are used (maximum security, must have YubiKey).
      '';
    };

    gpgAgentForwarding = {
      enable = mkEnableOption "GPG agent forwarding over SSH";

      hosts = mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "SSH host aliases that should forward the local GPG agent to the remote host.";
      };

      socketDir = mkOption {
        type = lib.types.str;
        default = "/run/user/1000/gnupg";
        description = "Runtime directory containing gpg-agent sockets on both local and remote hosts.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ===================================================================
    # Base SSH configuration
    # ===================================================================
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        settings = {
          "*" = {
            ServerAliveInterval = 180;
            ServerAliveCountMax = 3;
          };
        };
      };

      home.packages = with pkgs; [
        connect
      ];
    }

    (mkIf cfg.gpgAgentForwarding.enable {
      programs.ssh.settings = gpgAgentForwardingHosts;
    })

    # ===================================================================
    # FIDO2 configuration (when enabled)
    # ===================================================================
    (mkIf cfg.enableFido2 {
      # Install required FIDO2 packages
      home.packages = with pkgs; [
        libfido2 # FIDO2 library and tools
        yubikey-manager # YubiKey configuration tool
      ];
    })
  ]);
}
