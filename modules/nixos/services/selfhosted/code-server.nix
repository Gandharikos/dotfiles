{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.code-server;
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
  passwordEnv = "${cfg.stateDir}/password-env";
  oauth2SecretDir = "${cfg.stateDir}/oauth2";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  oauth2CookieSecretFile = "${oauth2SecretDir}/cookie-secret";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  dataDirGroup = if oidcEnabled then "kanidm" else "code-server";
  inherit (lib) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    listOf
    package
    port
    str
    ;
in
{
  options.dot.selfhosted.services.code-server =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "code-server";
      displayName = "code-server";
      subdomain = "code";
      defaultPort = 8084;
      defaultEnable = false;
    }
    // {
      stateDir = mkOption {
        type = str;
        default = "/var/lib/code-server";
        description = "Persistent state directory for code-server.";
      };

      packages = mkOption {
        type = listOf package;
        default = with pkgs; [
          bashInteractive
          cargo
          cmake
          coreutils
          findutils
          gcc
          gdb
          git
          gnumake
          gnugrep
          gnutar
          gzip
          nil
          nix
          nixfmt
          pkg-config
          python3
          rust-analyzer
          rustc
          rustfmt
          unzip
          zip
        ];
        description = "Packages exposed in code-server terminals.";
      };

      authProxy.port = mkOption {
        type = port;
        default = 4181;
        description = "Local oauth2-proxy port used when Kanidm protects code-server.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.code-server = {
        inherit (cfg)
          hostName
          localHostAlias
          ;
        inherit (proxyBackend) host port scheme;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "code-server" cfg) ];
      backups.paths = [ cfg.stateDir ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.code-server-users.members = [ "johnson" ];
      persons.johnson.groups = [ "code-server-users" ];
      systems.oauth2.code-server = {
        displayName = "code-server";
        originLanding = "https://${cfg.hostName}/";
        originUrl = "https://${cfg.hostName}/oauth2/callback";
        basicSecretFile = oauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.code-server-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    users = {
      groups.code-server = { };
      users.code-server = {
        isSystemUser = true;
        group = "code-server";
        home = cfg.stateDir;
        createHome = true;
        shell = pkgs.bashInteractive;
      };
    };

    systemd.tmpfiles.settings.code-server = {
      ${cfg.stateDir}.d = {
        user = "code-server";
        group = dataDirGroup;
        mode = "0750";
      };
      "${cfg.stateDir}/data".d = {
        user = "code-server";
        group = "code-server";
        mode = "0750";
      };
      "${cfg.stateDir}/extensions".d = {
        user = "code-server";
        group = "code-server";
        mode = "0750";
      };
      "${cfg.stateDir}/workspace".d = {
        user = "code-server";
        group = "code-server";
        mode = "0750";
      };
      "${cfg.stateDir}/.cargo".d = {
        user = "code-server";
        group = "code-server";
        mode = "0750";
      };
    };

    systemd.services = {
      code-server-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate code-server OAuth2 secrets";
        before = [
          "kanidm.service"
          "oauth2-proxy-code-server.service"
        ];
        requiredBy = [
          "kanidm.service"
          "oauth2-proxy-code-server.service"
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.coreutils}/bin/chgrp kanidm ${cfg.stateDir}
          ${pkgs.coreutils}/bin/chmod 0750 ${cfg.stateDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o code-server -g kanidm ${oauth2SecretDir}

          if [ ! -s ${oauth2ClientSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 > ${oauth2ClientSecretFile}
          fi

          cookie_secret="$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile} 2>/dev/null || true)"
          if [ ''${#cookie_secret} -ne 16 ] && [ ''${#cookie_secret} -ne 24 ] && [ ''${#cookie_secret} -ne 32 ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 16 > ${oauth2CookieSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown code-server:kanidm ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}

          {
            printf 'OAUTH2_PROXY_CLIENT_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2ClientSecretFile})"
            printf 'OAUTH2_PROXY_COOKIE_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile})"
          } > ${oauth2EnvFile}

          ${pkgs.coreutils}/bin/chown root:root ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
        '';
      };

      code-server-password = {
        description = "Generate code-server password";
        before = [ "code-server.service" ];
        requiredBy = [ "code-server.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o code-server -g ${dataDirGroup} ${cfg.stateDir}
          if [ ! -s ${passwordEnv} ]; then
            password="$(${pkgs.openssl}/bin/openssl rand -base64 24)"
            ${pkgs.coreutils}/bin/install -m 0600 -o code-server -g code-server /dev/null ${passwordEnv}
            printf 'PASSWORD=%s\n' "$password" > ${passwordEnv}
          fi
          ${pkgs.coreutils}/bin/chown code-server:code-server ${passwordEnv}
          ${pkgs.coreutils}/bin/chmod 0600 ${passwordEnv}
        '';
      };

      code-server = {
        description = "code-server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "code-server-password.service"
        ];
        requires = [ "code-server-password.service" ];
        path = cfg.packages;
        environment = {
          CARGO_HOME = "${cfg.stateDir}/.cargo";
          HOME = cfg.stateDir;
          NIX_CONFIG = "experimental-features = nix-command flakes";
          SHELL = getExe pkgs.bashInteractive;
        };
        script = ''
          exec ${getExe pkgs.code-server} \
            --auth ${if oidcEnabled then "none" else "password"} \
            --bind-addr ${cfg.host}:${toString cfg.port} \
            --user-data-dir ${cfg.stateDir}/data \
            --extensions-dir ${cfg.stateDir}/extensions \
            ${cfg.stateDir}/workspace
        '';
        serviceConfig = {
          EnvironmentFile = passwordEnv;
          Group = "code-server";
          Restart = "always";
          RestartSec = "10s";
          User = "code-server";
          WorkingDirectory = "${cfg.stateDir}/workspace";
        };
      };

      oauth2-proxy-code-server = mkIf oidcEnabled {
        description = "oauth2-proxy for code-server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "kanidm.service"
          "code-server.service"
          "code-server-oauth2-secrets.service"
        ];
        requires = [
          "kanidm.service"
          "code-server.service"
          "code-server-oauth2-secrets.service"
        ];
        script = ''
          exec ${getExe pkgs.oauth2-proxy} \
            --provider=oidc \
            --oidc-issuer-url=https://${kanidm.hostName}/oauth2/openid/code-server \
            --client-id=code-server \
            --http-address=http://${cfg.host}:${toString cfg.authProxy.port} \
            --redirect-url=https://${cfg.hostName}/oauth2/callback \
            --upstream=http://${cfg.host}:${toString cfg.port}/ \
            --scope="openid email profile" \
            --email-domain="*" \
            --reverse-proxy=true \
            --cookie-secure=true \
            --cookie-name=_code_server_oauth2_proxy \
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
