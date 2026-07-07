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
  oauth2SecretDir = "${cfg.stateDir}/oauth2";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  oauth2CookieSecretFile = "${oauth2SecretDir}/cookie-secret";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  dataDirGroup = if oidcEnabled then "kanidm" else "code-server";
  inherit (lib) getExe;
  inherit (lib.modules) mkForce mkIf;
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
        isNormalUser = mkForce false;
        isSystemUser = true;
        group = "code-server";
        home = cfg.stateDir;
        createHome = true;
        shell = pkgs.bashInteractive;
      };
    };

    services.code-server = {
      enable = true;
      package = pkgs.code-server;
      auth = if oidcEnabled then "none" else "password";
      inherit (cfg) host;
      inherit (cfg) port;
      user = "code-server";
      group = "code-server";
      extraPackages = cfg.packages;
      userDataDir = "${cfg.stateDir}/data";
      extensionsDir = "${cfg.stateDir}/extensions";
      disableTelemetry = true;
      disableUpdateCheck = true;
      extraEnvironment = {
        CARGO_HOME = "${cfg.stateDir}/.cargo";
        HOME = cfg.stateDir;
        NIX_CONFIG = "experimental-features = nix-command flakes";
        SHELL = getExe pkgs.bashInteractive;
      };
      extraArguments = [ "${cfg.stateDir}/workspace" ];
    };

    systemd.services.code-server.serviceConfig = {
      Restart = mkForce "always";
      RestartSec = "10s";
      WorkingDirectory = "${cfg.stateDir}/workspace";
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
      kanidm = mkIf oidcEnabled {
        after = [ "code-server-oauth2-secrets.service" ];
        requires = [ "code-server-oauth2-secrets.service" ];
      };

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
          ${lib.getExe' pkgs.coreutils "install"} -d -m 0750 -o code-server -g kanidm ${cfg.stateDir}
          ${lib.getExe' pkgs.coreutils "chown"} code-server:kanidm ${cfg.stateDir}
          ${lib.getExe' pkgs.coreutils "chmod"} 0750 ${cfg.stateDir}
          ${lib.getExe' pkgs.coreutils "install"} -d -m 0750 -o root -g kanidm ${oauth2SecretDir}

          if [ ! -s ${oauth2ClientSecretFile} ]; then
            ${lib.getExe' pkgs.openssl "openssl"} rand -base64 48 | ${lib.getExe' pkgs.coreutils "tr"} -d '\n' > ${oauth2ClientSecretFile}
          fi

          cookie_secret="$(${lib.getExe' pkgs.coreutils "cat"} ${oauth2CookieSecretFile} 2>/dev/null || true)"
          if [ ''${#cookie_secret} -ne 16 ] && [ ''${#cookie_secret} -ne 24 ] && [ ''${#cookie_secret} -ne 32 ]; then
            ${lib.getExe' pkgs.openssl "openssl"} rand -hex 16 > ${oauth2CookieSecretFile}
          fi

          ${lib.getExe' pkgs.coreutils "chown"} root:kanidm ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}
          ${lib.getExe' pkgs.coreutils "chmod"} 0440 ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}

          {
            printf 'OAUTH2_PROXY_CLIENT_SECRET=%s\n' "$(${lib.getExe' pkgs.coreutils "cat"} ${oauth2ClientSecretFile})"
            printf 'OAUTH2_PROXY_COOKIE_SECRET=%s\n' "$(${lib.getExe' pkgs.coreutils "cat"} ${oauth2CookieSecretFile})"
          } > ${oauth2EnvFile}

          ${lib.getExe' pkgs.coreutils "chown"} root:root ${oauth2EnvFile}
          ${lib.getExe' pkgs.coreutils "chmod"} 0400 ${oauth2EnvFile}
        '';
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
