{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.radicale;
  userName = config.dot.primaryUser;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) str;
in
{
  options.dot.selfhosted.services.radicale =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "radicale";
      subdomain = "dav";
      defaultPort = 5232;
      defaultEnable = false;
    }
    // {
      dataDir = mkOption {
        type = str;
        default = "/var/lib/radicale";
        description = "Radicale persistent data directory.";
      };

      authFile = mkOption {
        type = str;
        default = "${cfg.dataDir}/users";
        description = "Radicale htpasswd authentication file.";
      };

      passwordFile = mkOption {
        type = str;
        default = "${cfg.dataDir}/${userName}-password";
        description = "File containing the generated Radicale password for the primary user.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.radicale = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "radicale" cfg) ];
      backups.paths = [ cfg.dataDir ];
    };

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "${cfg.host}:${toString cfg.port}" ];
        auth = {
          type = "htpasswd";
          htpasswd_filename = cfg.authFile;
          htpasswd_encryption = "bcrypt";
        };
        storage.filesystem_folder = "${cfg.dataDir}/collections";
        web.type = "internal";
      };
      rights = {
        root = {
          user = ".+";
          collection = "";
          permissions = "R";
        };
        principal = {
          user = ".+";
          collection = "{user}";
          permissions = "RW";
        };
        collections = {
          user = ".+";
          collection = "{user}/[^/]+";
          permissions = "rw";
        };
      };
    };

    systemd.tmpfiles.settings.selfhosted-radicale = {
      ${cfg.dataDir}.d = {
        user = "radicale";
        group = "radicale";
        mode = "0750";
      };
      "${cfg.dataDir}/collections".d = {
        user = "radicale";
        group = "radicale";
        mode = "0750";
      };
    };

    systemd.services = {
      radicale = {
        after = [ "radicale-htpasswd.service" ];
        requires = [ "radicale-htpasswd.service" ];
      };

      radicale-htpasswd = {
        description = "Generate Radicale htpasswd file";
        before = [ "radicale.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o radicale -g radicale ${cfg.dataDir}

          if [ ! -s ${cfg.passwordFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 24 > ${cfg.passwordFile}
          fi

          ${pkgs.coreutils}/bin/chown root:root ${cfg.passwordFile}
          ${pkgs.coreutils}/bin/chmod 0600 ${cfg.passwordFile}

          if [ ! -s ${cfg.authFile} ]; then
            ${pkgs.apacheHttpd}/bin/htpasswd -B -b -c ${cfg.authFile} ${userName} "$(${pkgs.coreutils}/bin/cat ${cfg.passwordFile})"
          fi

          ${pkgs.coreutils}/bin/chown radicale:radicale ${cfg.authFile}
          ${pkgs.coreutils}/bin/chmod 0640 ${cfg.authFile}
        '';
      };
    };
  };
}
