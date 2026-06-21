{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.mmdl;
  envFile = "${cfg.dataDir}/env";
  aesSecretFile = "${cfg.dataDir}/aes-password";
  nextAuthSecretFile = "${cfg.dataDir}/nextauth-secret";
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) bool str;
in
{
  options.dot.selfhosted.services.mmdl =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "mmdl";
      displayName = "MMDL";
      subdomain = "life";
      defaultPort = 3005;
      defaultEnable = false;
    }
    // {
      dataDir = mkOption {
        type = str;
        default = "/var/lib/mmdl";
        description = "MMDL persistent data directory.";
      };

      image = mkOption {
        type = str;
        default = "intriin/mmdl:latest";
        description = "OCI image used to run MMDL.";
      };

      disableRegistration = mkOption {
        type = bool;
        default = false;
        description = "Whether MMDL user registration is disabled.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.mmdl = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "mmdl" cfg) ];
      backups.paths = [ cfg.dataDir ];
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "mmdl" ];
      ensureUsers = [
        {
          name = "mmdl";
          ensureDBOwnership = true;
        }
      ];
      authentication = ''
        host mmdl mmdl 127.0.0.1/32 trust
      '';
    };

    virtualisation.oci-containers.containers.mmdl = {
      inherit (cfg) image;
      autoStart = true;
      environmentFiles = [ envFile ];
      ports = [ "${cfg.host}:${toString cfg.port}:3000" ];
      extraOptions = [
        "--add-host=host.containers.internal:host-gateway"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges"
      ];
    };

    systemd.tmpfiles.settings.selfhosted-mmdl.${cfg.dataDir}.d = {
      user = "root";
      group = "root";
      mode = "0700";
    };

    systemd.services = {
      podman-mmdl = {
        after = [
          "mmdl-env.service"
          "postgresql.service"
        ];
        requires = [
          "mmdl-env.service"
          "postgresql.service"
        ];
      };

      mmdl-env = {
        description = "Generate MMDL environment";
        before = [ "podman-mmdl.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root ${cfg.dataDir}

          if [ ! -s ${aesSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 > ${aesSecretFile}
          fi

          if [ ! -s ${nextAuthSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 > ${nextAuthSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown root:root ${aesSecretFile} ${nextAuthSecretFile}
          ${pkgs.coreutils}/bin/chmod 0600 ${aesSecretFile} ${nextAuthSecretFile}

          {
            printf 'NEXT_BASE_URL=https://${cfg.hostName}/\n'
            printf 'NEXT_PUBLIC_API_URL=https://${cfg.hostName}/api\n'
            printf 'DB_HOST=host.containers.internal\n'
            printf 'DB_USER=mmdl\n'
            printf 'DB_PASS=\n'
            printf 'DB_PORT=5432\n'
            printf 'DB_DIALECT=postgres\n'
            printf 'DB_NAME=mmdl\n'
            printf 'DB_CHARSET=utf8mb4\n'
            printf 'DB_COLLATE=utf8mb4_0900_ai_ci\n'
            printf 'AES_PASSWORD=%s\n' "$(${pkgs.coreutils}/bin/cat ${aesSecretFile})"
            printf 'USE_NEXT_AUTH=false\n'
            printf 'NEXTAUTH_URL=https://${cfg.hostName}/\n'
            printf 'NEXTAUTH_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${nextAuthSecretFile})"
            printf 'DISABLE_USER_REGISTRATION=${lib.boolToString cfg.disableRegistration}\n'
            printf 'DOCKER_INSTALL=true\n'
            printf 'NEXT_PUBLIC_DEBUG_MODE=false\n'
            printf 'NEXT_API_DEBUG_MODE=false\n'
            printf 'NEXT_PUBLIC_TEST_MODE=false\n'
          } > ${envFile}

          ${pkgs.coreutils}/bin/chown root:root ${envFile}
          ${pkgs.coreutils}/bin/chmod 0600 ${envFile}
        '';
      };
    };
  };
}
