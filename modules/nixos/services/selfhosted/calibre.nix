{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted.services.calibre;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  primaryUser = config.dot.primaryUser;
  primaryEmail = config.dot.admin.email;
  secretsFile = "${self}/secrets/services/calibre.yaml";
  proxyBackend =
    if oidcEnabled then
      {
        inherit (cfg) host scheme;
        port = cfg.authProxy.port;
      }
    else
      cfg;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    nullOr
    path
    port
    str
    ;
in
{
  options.dot.selfhosted.services.calibre =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "calibre";
      subdomain = "book";
      defaultPort = 8080;
      defaultEnable = false;
    }
    // {
      dataDir = mkOption {
        type = str;
        default = "/var/lib/calibre-web";
        description = "Calibre-Web application data directory.";
      };

      libraryDir = mkOption {
        type = nullOr path;
        default = "/var/lib/calibre-web/library";
        description = "Existing Calibre library directory containing metadata.db.";
      };

      enableBookUploading = mkOption {
        type = bool;
        default = true;
        description = "Whether Calibre-Web allows book uploads.";
      };

      authProxy.port = mkOption {
        type = port;
        default = 4180;
        description = "Local oauth2-proxy port used when Kanidm protects Calibre-Web.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.calibre = {
        inherit (cfg) hostName localHostAlias;
        inherit (proxyBackend) host port scheme;
      };
      backups.paths = [
        cfg.dataDir
      ]
      ++ lib.optional (cfg.libraryDir != null) cfg.libraryDir;
    };

    sops.secrets.calibre-oauth2-cookie-secret = mkIf oidcEnabled {
      sopsFile = secretsFile;
      key = "oauth2-cookie-secret";
    };

    sops.templates.calibre-oauth2-proxy-env = mkIf oidcEnabled {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        OAUTH2_PROXY_CLIENT_SECRET=${config.sops.placeholder.kanidm-oauth2-calibre}
        OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder.calibre-oauth2-cookie-secret}
      '';
      restartUnits = [ "oauth2-proxy.service" ];
    };

    services.calibre-web = {
      enable = true;
      inherit (cfg) dataDir;
      listen = {
        ip = cfg.host;
        inherit (cfg) port;
      };
      options = {
        calibreLibrary = cfg.libraryDir;
        inherit (cfg) enableBookUploading;
        reverseProxyAuth = mkIf oidcEnabled {
          enable = true;
          header = "X-Forwarded-User";
        };
      };
    };

    systemd.services = {
      calibre-web-library-init = mkIf (cfg.libraryDir != null) {
        description = "Initialize Calibre-Web library";
        before = [ "calibre-web.service" ];
        requiredBy = [ "calibre-web.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "calibre-web";
          Group = "calibre-web";
          StateDirectory = "calibre-web";
        };
        script = ''
          install -d -m 0700 "${cfg.libraryDir}"
          if [ ! -f "${cfg.libraryDir}/metadata.db" ]; then
            ${pkgs.calibre}/bin/calibredb --library-path "${cfg.libraryDir}" list >/dev/null
          fi
        '';
      };

      calibre-web.serviceConfig.ExecStartPost = mkIf oidcEnabled (
        pkgs.writeShellScript "calibre-web-ensure-primary-user" ''
          ${pkgs.sqlite}/bin/sqlite3 "${cfg.dataDir}/app.db" <<'SQL'
          update user
          set name = '${primaryUser}',
              email = '${primaryEmail}'
          where name = 'admin'
            and not exists (select 1 from user where name = '${primaryUser}');

          insert into user (
            name,
            email,
            role,
            password,
            kindle_mail,
            locale,
            sidebar_view,
            default_language,
            view_settings,
            kobo_only_shelves_sync
          )
          select
            '${primaryUser}',
            '${primaryEmail}',
            479,
            null,
            null,
            'en',
            262143,
            'all',
            '{}',
            0
          where not exists (select 1 from user where name = '${primaryUser}');
          SQL
        ''
      );
    };

    services.oauth2-proxy = mkIf oidcEnabled {
      enable = true;
      provider = "oidc";
      oidcIssuerUrl = "https://${kanidm.hostName}/oauth2/openid/calibre";
      clientID = "calibre";
      keyFile = config.sops.templates.calibre-oauth2-proxy-env.path;
      httpAddress = "http://${cfg.host}:${toString cfg.authProxy.port}";
      redirectURL = "https://${cfg.hostName}/oauth2/callback";
      upstream = "http://${cfg.host}:${toString cfg.port}/";
      scope = "openid email profile";
      email.domains = [ "*" ];
      reverseProxy = true;
      trustedProxyIP = [
        "127.0.0.1/32"
        "::1/128"
      ];
      passBasicAuth = true;
      passHostHeader = true;
      cookie = {
        name = "_calibre_oauth2_proxy_v2";
        domain = cfg.hostName;
      };
      extraConfig = {
        code-challenge-method = "S256";
        oidc-email-claim = "preferred_username";
        prefer-email-to-user = true;
        skip-provider-button = true;
      };
    };

    systemd.services.oauth2-proxy = mkIf oidcEnabled {
      after = [
        "kanidm.service"
        "sops-install-secrets.service"
      ];
      requires = [ "sops-install-secrets.service" ];
    };
  };
}
