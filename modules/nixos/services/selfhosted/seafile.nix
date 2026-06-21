{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.seafile;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  proxyBackend =
    if oidcEnabled then
      {
        inherit (cfg) host scheme;
        port = cfg.authProxy.port;
      }
    else
      cfg;
  secretDir = "${cfg.dataDir}/secrets";
  envFile = "${cfg.dataDir}/seafile.env";
  dbEnvFile = "${cfg.dataDir}/mariadb.env";
  dbRootPasswordFile = "${secretDir}/db-root-password";
  dbPasswordFile = "${secretDir}/db-password";
  adminPasswordFile = "${secretDir}/admin-password";
  jwtPrivateKeyFile = "${secretDir}/jwt-private-key";
  oauth2SecretDir = "${cfg.dataDir}/oauth2";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  oauth2CookieSecretFile = "${oauth2SecretDir}/cookie-secret";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  dataDirGroup = if oidcEnabled then "kanidm" else "root";
  inherit (lib) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) port str;
in
{
  options.dot.selfhosted.services.seafile =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "seafile";
      displayName = "Seafile";
      subdomain = "files";
      defaultPort = 8085;
      defaultEnable = false;
    }
    // {
      dataDir = mkOption {
        type = str;
        default = "/var/lib/seafile";
        description = "Seafile persistent data directory.";
      };

      image = mkOption {
        type = str;
        default = "seafileltd/seafile-mc:12.0-latest";
        description = "Seafile OCI image.";
      };

      dbImage = mkOption {
        type = str;
        default = "mariadb:10.11";
        description = "MariaDB OCI image used by Seafile.";
      };

      memcachedImage = mkOption {
        type = str;
        default = "memcached:1.6.29";
        description = "Memcached OCI image used by Seafile.";
      };

      dbPort = mkOption {
        type = port;
        default = 3307;
        description = "Local MariaDB port used by Seafile.";
      };

      memcachedPort = mkOption {
        type = port;
        default = 11212;
        description = "Local Memcached port used by Seafile.";
      };

      authProxy.port = mkOption {
        type = port;
        default = 4183;
        description = "Local oauth2-proxy port used when Kanidm protects Seafile.";
      };
    };

  config = mkIf cfg.enable {
    dot = {
      virtual.podman.enable = true;
      selfhosted = {
        proxyBackends.seafile = {
          inherit (cfg)
            hostName
            localHostAlias
            ;
          inherit (proxyBackend) host port scheme;
        };
        services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "seafile" cfg) ];
        backups.paths = [ cfg.dataDir ];
      };
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.seafile-users.members = [ "johnson" ];
      persons.johnson.groups = [ "seafile-users" ];
      systems.oauth2.seafile = {
        displayName = "Seafile";
        originLanding = "https://${cfg.hostName}/";
        originUrl = "https://${cfg.hostName}/oauth2/callback";
        basicSecretFile = oauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.seafile-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    systemd.tmpfiles.settings.selfhosted-seafile = {
      ${cfg.dataDir}.d = {
        user = "root";
        group = dataDirGroup;
        mode = "0750";
      };
      "${cfg.dataDir}/mysql".d = {
        user = "root";
        group = "root";
        mode = "0700";
      };
      "${cfg.dataDir}/shared".d = {
        user = "root";
        group = "root";
        mode = "0750";
      };
    };

    virtualisation.oci-containers.containers = {
      seafile-db = {
        image = cfg.dbImage;
        autoStart = true;
        environmentFiles = [ dbEnvFile ];
        volumes = [ "${cfg.dataDir}/mysql:/var/lib/mysql" ];
        ports = [ "127.0.0.1:${toString cfg.dbPort}:3306" ];
        extraOptions = [ "--security-opt=no-new-privileges" ];
      };

      seafile-memcached = {
        image = cfg.memcachedImage;
        autoStart = true;
        cmd = [
          "memcached"
          "-m"
          "256"
        ];
        ports = [ "127.0.0.1:${toString cfg.memcachedPort}:11211" ];
        extraOptions = [
          "--cap-drop=ALL"
          "--security-opt=no-new-privileges"
        ];
      };

      seafile = {
        inherit (cfg) image;
        autoStart = true;
        environmentFiles = [ envFile ];
        volumes = [ "${cfg.dataDir}/shared:/shared" ];
        ports = [ "${cfg.host}:${toString cfg.port}:80" ];
        extraOptions = [
          "--add-host=host.containers.internal:host-gateway"
          "--security-opt=no-new-privileges"
        ];
      };
    };

    systemd.services = {
      seafile-env = {
        description = "Generate Seafile container environment";
        before = [
          "podman-seafile.service"
          "podman-seafile-db.service"
        ];
        requiredBy = [
          "podman-seafile.service"
          "podman-seafile-db.service"
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g ${dataDirGroup} ${cfg.dataDir}
          ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root ${secretDir}
          ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root ${cfg.dataDir}/mysql
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g root ${cfg.dataDir}/shared

          if [ ! -s ${dbRootPasswordFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 32 > ${dbRootPasswordFile}
          fi
          if [ ! -s ${dbPasswordFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 32 > ${dbPasswordFile}
          fi
          if [ ! -s ${adminPasswordFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 24 > ${adminPasswordFile}
          fi
          if [ ! -s ${jwtPrivateKeyFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 > ${jwtPrivateKeyFile}
          fi

          ${pkgs.coreutils}/bin/chown root:root ${secretDir}/*
          ${pkgs.coreutils}/bin/chmod 0600 ${secretDir}/*

          db_root_password="$(${pkgs.coreutils}/bin/cat ${dbRootPasswordFile})"
          db_password="$(${pkgs.coreutils}/bin/cat ${dbPasswordFile})"
          admin_password="$(${pkgs.coreutils}/bin/cat ${adminPasswordFile})"
          jwt_private_key="$(${pkgs.coreutils}/bin/cat ${jwtPrivateKeyFile})"

          {
            printf 'MYSQL_ROOT_PASSWORD=%s\n' "$db_root_password"
            printf 'MYSQL_LOG_CONSOLE=true\n'
          } > ${dbEnvFile}

          {
            printf 'TIME_ZONE=UTC\n'
            printf 'SEAFILE_SERVER_HOSTNAME=${cfg.hostName}\n'
            printf 'SEAFILE_SERVER_PROTOCOL=${if config.dot.selfhosted.useHttps then "https" else "http"}\n'
            printf 'SITE_ROOT=/\n'
            printf 'NON_ROOT=false\n'
            printf 'SEAFILE_LOG_TO_STDOUT=true\n'
            printf 'ENABLE_SEADOC=false\n'
            printf 'ENABLE_NOTIFICATION_SERVER=false\n'
            printf 'JWT_PRIVATE_KEY=%s\n' "$jwt_private_key"
            printf 'CACHE_PROVIDER=memcached\n'
            printf 'MEMCACHED_HOST=host.containers.internal\n'
            printf 'MEMCACHED_PORT=${toString cfg.memcachedPort}\n'
            printf 'SEAFILE_MYSQL_DB_HOST=host.containers.internal\n'
            printf 'SEAFILE_MYSQL_DB_PORT=${toString cfg.dbPort}\n'
            printf 'SEAFILE_MYSQL_DB_USER=seafile\n'
            printf 'SEAFILE_MYSQL_DB_PASSWORD=%s\n' "$db_password"
            printf 'INIT_SEAFILE_MYSQL_ROOT_PASSWORD=%s\n' "$db_root_password"
            printf 'SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db\n'
            printf 'SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db\n'
            printf 'SEAFILE_MYSQL_DB_SEAHUB_DB_NAME=seahub_db\n'
            printf 'INIT_SEAFILE_ADMIN_EMAIL=${config.dot.admin.email}\n'
            printf 'INIT_SEAFILE_ADMIN_PASSWORD=%s\n' "$admin_password"
            printf 'DB_HOST=host.containers.internal\n'
            printf 'DB_PORT=${toString cfg.dbPort}\n'
            printf 'DB_ROOT_PASSWD=%s\n' "$db_root_password"
            printf 'SEAFILE_ADMIN_EMAIL=${config.dot.admin.email}\n'
            printf 'SEAFILE_ADMIN_PASSWORD=%s\n' "$admin_password"
          } > ${envFile}

          ${pkgs.coreutils}/bin/chown root:root ${envFile} ${dbEnvFile}
          ${pkgs.coreutils}/bin/chmod 0600 ${envFile} ${dbEnvFile}
        '';
      };

      seafile-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate Seafile OAuth2 secrets";
        after = [ "seafile-env.service" ];
        requires = [ "seafile-env.service" ];
        before = [
          "kanidm.service"
          "oauth2-proxy-seafile.service"
        ];
        requiredBy = [
          "kanidm.service"
          "oauth2-proxy-seafile.service"
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.coreutils}/bin/chgrp kanidm ${cfg.dataDir}
          ${pkgs.coreutils}/bin/chmod 0750 ${cfg.dataDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${oauth2SecretDir}

          if [ ! -s ${oauth2ClientSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 > ${oauth2ClientSecretFile}
          fi

          cookie_secret="$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile} 2>/dev/null || true)"
          if [ ''${#cookie_secret} -ne 16 ] && [ ''${#cookie_secret} -ne 24 ] && [ ''${#cookie_secret} -ne 32 ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 16 > ${oauth2CookieSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown root:kanidm ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}

          {
            printf 'OAUTH2_PROXY_CLIENT_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2ClientSecretFile})"
            printf 'OAUTH2_PROXY_COOKIE_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile})"
          } > ${oauth2EnvFile}

          ${pkgs.coreutils}/bin/chown root:root ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
        '';
      };

      podman-seafile-db = {
        after = [ "seafile-env.service" ];
        requires = [ "seafile-env.service" ];
      };

      podman-seafile = {
        after = [
          "seafile-env.service"
          "podman-seafile-db.service"
          "podman-seafile-memcached.service"
        ];
        requires = [
          "seafile-env.service"
          "podman-seafile-db.service"
          "podman-seafile-memcached.service"
        ];
      };

      oauth2-proxy-seafile = mkIf oidcEnabled {
        description = "oauth2-proxy for Seafile";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "kanidm.service"
          "podman-seafile.service"
          "seafile-oauth2-secrets.service"
        ];
        requires = [
          "kanidm.service"
          "podman-seafile.service"
          "seafile-oauth2-secrets.service"
        ];
        script = ''
          exec ${getExe pkgs.oauth2-proxy} \
            --provider=oidc \
            --oidc-issuer-url=https://${kanidm.hostName}/oauth2/openid/seafile \
            --client-id=seafile \
            --http-address=http://${cfg.host}:${toString cfg.authProxy.port} \
            --redirect-url=https://${cfg.hostName}/oauth2/callback \
            --upstream=http://${cfg.host}:${toString cfg.port}/ \
            --scope="openid email profile" \
            --email-domain="*" \
            --reverse-proxy=true \
            --cookie-secure=true \
            --cookie-name=_seafile_oauth2_proxy \
            --cookie-domain=${cfg.hostName} \
            --pass-basic-auth=true \
            --pass-host-header=true \
            --set-xauthrequest=true \
            --skip-provider-button=true \
            --code-challenge-method=S256 \
            --oidc-email-claim=preferred_username \
            --prefer-email-to-user=true
        '';
        serviceConfig = {
          DynamicUser = true;
          EnvironmentFile = oauth2EnvFile;
          Restart = "always";
          RestartSec = "10s";
        };
      };
    };
  };
}
