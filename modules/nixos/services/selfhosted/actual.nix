{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.actual;
  serverPasswordFile = "${config.services.actual.settings.dataDir}/server-password";
  localPasswordMarker = "${config.services.actual.settings.dataDir}/local-password-applied";
  actualPasswordBootstrapScript = pkgs.writeText "actual-password-bootstrap.mjs" ''
    import { readFileSync, writeFileSync } from "node:fs";
    import { pathToFileURL } from "node:url";

    const accountDb = await import(pathToFileURL(process.argv[2]).href);
    const password = readFileSync(process.argv[3], "utf8").trim();
    const marker = process.argv[4];

    const { error } = await accountDb.t({ password }, true);
    if (error) {
      throw new Error("failed to bootstrap Actual password auth: " + error);
    }

    const disableOpenIdResult = await accountDb.n({ password });
    if (disableOpenIdResult?.error) {
      throw new Error("failed to disable Actual OpenID auth: " + disableOpenIdResult.error);
    }

    writeFileSync(marker, "ok\n", { mode: 0o600 });
  '';
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.actual = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "actual";
    displayName = "Actual Budget";
    subdomain = "budget";
    defaultPort = 5006;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.actual = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "actual" cfg) ];
      backups.paths = [ config.services.actual.settings.dataDir ];
    };

    services.actual = {
      enable = true;
      settings = {
        hostname = cfg.host;
        inherit (cfg) port;
        dataDir = "/var/lib/actual";
      };
    };

    users = {
      groups.actual = { };
      users.actual = {
        isSystemUser = true;
        group = "actual";
      };
    };

    systemd.services = {
      actual = {
        preStart = lib.mkAfter ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o actual -g actual ${config.services.actual.settings.dataDir}

          if [ ! -s ${serverPasswordFile} ]; then
            umask 077
            ${pkgs.openssl}/bin/openssl rand -base64 48 > ${serverPasswordFile}
          fi

          ${pkgs.coreutils}/bin/chown actual:actual ${serverPasswordFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${serverPasswordFile}

          if [ ! -e ${localPasswordMarker} ]; then
            account_db="$(${pkgs.findutils}/bin/find ${config.services.actual.package}/lib/actual/packages/sync-server/chunks -maxdepth 1 -name 'account-db-*.js' -print -quit)"
            ${pkgs.nodejs_22}/bin/node ${actualPasswordBootstrapScript} "$account_db" ${serverPasswordFile} ${localPasswordMarker}
            ${pkgs.coreutils}/bin/chown actual:actual ${localPasswordMarker}
            ${pkgs.coreutils}/bin/chmod 0600 ${localPasswordMarker}
          fi
        '';
        serviceConfig.DynamicUser = lib.mkForce false;
      };
    };
  };
}
