{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.fava;
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
  oauth2SecretDir = "${cfg.dataDir}/oauth2";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  oauth2CookieSecretFile = "${oauth2SecretDir}/cookie-secret";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  dataDirGroup = if oidcEnabled then "kanidm" else "fava";
  forgejo = config.dot.selfhosted.services.forgejo;
  deployScript = pkgs.writeShellScript "selfhosted-ledger-deploy" ''
        set -eu

        umask 0027
        export HOME=${cfg.dataDir}
        source_dir=${cfg.dataDir}/source
        worktree_dir=${cfg.dataDir}/worktree
        git_safe="${lib.getExe' pkgs.git "git"} -c safe.directory=$source_dir"

        install -d -m 0750 -o fava -g ${dataDirGroup} ${cfg.dataDir}

        if ${lib.getExe' pkgs.git "git"} ls-remote ${cfg.repositoryUrl} HEAD >/dev/null 2>&1; then
          if [ ! -d "$source_dir" ]; then
            ${lib.getExe' pkgs.git "git"} clone --mirror ${cfg.repositoryUrl} "$source_dir"
          else
            $git_safe -C "$source_dir" remote set-url origin ${cfg.repositoryUrl}
            $git_safe -C "$source_dir" remote update --prune
          fi

          rm -rf "$worktree_dir"
          $git_safe --git-dir "$source_dir" worktree add --force "$worktree_dir" ${cfg.branch}
          trap '$git_safe --git-dir "$source_dir" worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true' EXIT

          if [ -s "$worktree_dir/${cfg.ledgerFileName}" ]; then
            install -m 0640 -o fava -g fava "$worktree_dir/${cfg.ledgerFileName}" ${cfg.ledgerFile}
          elif [ ! -s ${cfg.ledgerFile} ]; then
            ${lib.getExe' pkgs.coreutils "cat"} > ${cfg.ledgerFile} <<'EOF'
    option "title" "Johnson Ledger"
    option "operating_currency" "USD"

    2026-01-01 open Assets:Cash USD
    2026-01-01 open Equity:Opening-Balances USD
    EOF
            ${lib.getExe' pkgs.coreutils "chown"} fava:fava ${cfg.ledgerFile}
            ${lib.getExe' pkgs.coreutils "chmod"} 0640 ${cfg.ledgerFile}
          fi
        elif [ ! -s ${cfg.ledgerFile} ]; then
          ${lib.getExe' pkgs.coreutils "cat"} > ${cfg.ledgerFile} <<'EOF'
    option "title" "Johnson Ledger"
    option "operating_currency" "USD"

    2026-01-01 open Assets:Cash USD
    2026-01-01 open Equity:Opening-Balances USD
    EOF
          ${lib.getExe' pkgs.coreutils "chown"} fava:fava ${cfg.ledgerFile}
          ${lib.getExe' pkgs.coreutils "chmod"} 0640 ${cfg.ledgerFile}
        fi
  '';
  inherit (lib) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    int
    listOf
    package
    port
    str
    ;
in
{
  options.dot.selfhosted.services.fava =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "fava";
      displayName = "Fava";
      subdomain = "ledger";
      defaultPort = 5000;
      defaultEnable = false;
    }
    // {
      package = mkOption {
        type = package;
        default = pkgs.fava;
        description = "Fava package to run.";
      };

      dataDir = mkOption {
        type = str;
        default = "/var/lib/fava";
        description = "Fava and Beancount data directory.";
      };

      ledgerFile = mkOption {
        type = str;
        default = "${cfg.dataDir}/main.bean";
        description = "Beancount ledger opened by Fava.";
      };

      ledgerFileName = mkOption {
        type = str;
        default = "main.bean";
        description = "Ledger file expected in the Forgejo repository.";
      };

      readOnly = mkOption {
        type = bool;
        default = true;
        description = "Whether Fava is started in read-only mode.";
      };

      repositoryOwner = mkOption {
        type = str;
        default = config.dot.primaryUser;
        description = "Forgejo owner used for the Beancount ledger repository.";
      };

      repositoryName = mkOption {
        type = str;
        default = "ledger";
        description = "Forgejo repository name used for the Beancount ledger source.";
      };

      oldRepositoryNames = mkOption {
        type = listOf str;
        default = [ "budget" ];
        description = "Old repository names to rename to the configured ledger repository.";
      };

      repositoryUrl = mkOption {
        type = str;
        default = "http://${forgejo.host}:${toString forgejo.port}/${cfg.repositoryOwner}/${cfg.repositoryName}.git";
        description = "Git URL used by the deploy hook to fetch the ledger.";
      };

      branch = mkOption {
        type = str;
        default = "main";
        description = "Branch deployed to Fava.";
      };

      webhookPort = mkOption {
        type = int;
        default = 9010;
        description = "Local port used by Forgejo to trigger ledger deployment.";
      };

      authProxy.port = mkOption {
        type = port;
        default = 4182;
        description = "Local oauth2-proxy port used when Kanidm protects Fava.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.fava = {
        inherit (cfg)
          hostName
          localHostAlias
          ;
        inherit (proxyBackend) host port scheme;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "fava" cfg) ];
      backups.paths = [ cfg.dataDir ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.fava-users.members = [ "johnson" ];
      persons.johnson.groups = [ "fava-users" ];
      systems.oauth2.fava = {
        displayName = "Fava";
        originLanding = "https://${cfg.hostName}/";
        originUrl = "https://${cfg.hostName}/oauth2/callback";
        basicSecretFile = oauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.fava-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    users = {
      groups.fava = { };
      users.fava = {
        isSystemUser = true;
        group = "fava";
        home = cfg.dataDir;
        createHome = true;
      };
    };

    systemd.tmpfiles.settings.selfhosted-fava.${cfg.dataDir}.d = {
      user = "fava";
      group = dataDirGroup;
      mode = "0750";
    };

    systemd.services = {
      kanidm = mkIf oidcEnabled {
        after = [ "fava-oauth2-secrets.service" ];
        requires = [ "fava-oauth2-secrets.service" ];
      };

      fava-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate Fava OAuth2 secrets";
        before = [
          "kanidm.service"
          "oauth2-proxy-fava.service"
        ];
        requiredBy = [
          "kanidm.service"
          "oauth2-proxy-fava.service"
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${lib.getExe' pkgs.coreutils "install"} -d -m 0750 -o fava -g kanidm ${cfg.dataDir}
          ${lib.getExe' pkgs.coreutils "chown"} fava:kanidm ${cfg.dataDir}
          ${lib.getExe' pkgs.coreutils "chmod"} 0750 ${cfg.dataDir}
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

      fava-ledger-init = {
        description = "Initialize Fava Beancount ledger";
        before = [ "fava.service" ];
        requiredBy = [ "fava.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${lib.getExe' pkgs.coreutils "install"} -d -m 0750 -o fava -g ${dataDirGroup} ${cfg.dataDir}
          if [ ! -s ${cfg.ledgerFile} ]; then
            ${deployScript}
          fi
        '';
      };

      selfhosted-ledger-deploy = {
        description = "Deploy the self-hosted Beancount ledger";
        after = lib.optional forgejo.enable "forgejo.service";
        wants = lib.optional forgejo.enable "forgejo.service";
        wantedBy = [ "multi-user.target" ];
        path = [
          pkgs.git
        ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
        };
        script = "${deployScript}";
      };

      selfhosted-ledger-forgejo = mkIf forgejo.enable {
        description = "Create Forgejo ledger repository and deploy webhook";
        after = [ "forgejo.service" ];
        requires = [ "forgejo.service" ];
        before = [ "selfhosted-ledger-deploy.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [
          config.services.forgejo.package
          pkgs.coreutils
          pkgs.curl
          pkgs.gawk
          pkgs.jq
          pkgs.openssl
        ];
        serviceConfig = {
          Type = "oneshot";
          User = "forgejo";
          Group = "forgejo";
        };
        script = ''
          set -eu

          forgejo='${getExe config.services.forgejo.package}'
          config_file='${config.services.forgejo.customDir}/conf/app.ini'
          work_path='${config.services.forgejo.stateDir}'
          credential_dir='${config.services.forgejo.stateDir}/selfhosted-ledger'
          password_file="$credential_dir/${cfg.repositoryOwner}-password"
          token_file="$credential_dir/${cfg.repositoryOwner}-bootstrap-token"
          api='http://${forgejo.host}:${toString forgejo.port}/api/v1'
          hook_url='http://127.0.0.1:${toString cfg.webhookPort}/hooks/deploy-ledger'

          install -d -m 0700 "$credential_dir"

          if ! "$forgejo" admin user list --config "$config_file" --work-path "$work_path" \
            | ${lib.getExe' pkgs.gawk "awk"} 'NR > 1 && $2 == "${cfg.repositoryOwner}" { found = 1 } END { exit !found }'
          then
            if [ ! -s "$password_file" ]; then
              ${lib.getExe' pkgs.openssl "openssl"} rand -base64 24 > "$password_file"
              chmod 0600 "$password_file"
            fi

            "$forgejo" admin user create \
              --config "$config_file" \
              --work-path "$work_path" \
              --username ${cfg.repositoryOwner} \
              --password "$(${lib.getExe' pkgs.coreutils "cat"} "$password_file")" \
              --email ${config.dot.admin.email} \
              --admin \
              --must-change-password=false
          fi

          if [ ! -s "$token_file" ]; then
            "$forgejo" admin user generate-access-token \
              --config "$config_file" \
              --work-path "$work_path" \
              --username ${cfg.repositoryOwner} \
              --token-name selfhosted-ledger-bootstrap \
              --scopes write:user,write:repository,read:user \
              --raw > "$token_file"
            chmod 0600 "$token_file"
          fi

          token="$(${lib.getExe' pkgs.coreutils "cat"} "$token_file")"
          auth_header="Authorization: token $token"

          repo_status="$(${lib.getExe' pkgs.curl "curl"} -sS -o /dev/null -w '%{http_code}' -H "$auth_header" "$api/repos/${cfg.repositoryOwner}/${cfg.repositoryName}")"
          if [ "$repo_status" = 404 ]; then
            for old_repo in ${lib.escapeShellArgs cfg.oldRepositoryNames}; do
              old_status="$(${lib.getExe' pkgs.curl "curl"} -sS -o /dev/null -w '%{http_code}' -H "$auth_header" "$api/repos/${cfg.repositoryOwner}/$old_repo")"
              if [ "$old_status" = 200 ]; then
                rename_payload="$(${lib.getExe' pkgs.jq "jq"} -cn \
                  --arg name ${cfg.repositoryName} \
                  --arg description "Private Beancount ledger source for ${cfg.hostName}" \
                  '{name:$name, private:true, description:$description}')"
                ${lib.getExe' pkgs.curl "curl"} -fsS -X PATCH -H "$auth_header" -H 'Content-Type: application/json' --data "$rename_payload" "$api/repos/${cfg.repositoryOwner}/$old_repo" >/dev/null
                repo_status=200
                break
              fi
            done
          fi

          if [ "$repo_status" = 404 ]; then
            repo_payload="$(${lib.getExe' pkgs.jq "jq"} -cn \
              --arg name ${cfg.repositoryName} \
              --arg branch ${cfg.branch} \
              '{name:$name, private:true, auto_init:true, default_branch:$branch, description:"Private Beancount ledger source"}')"
            ${lib.getExe' pkgs.curl "curl"} -fsS -X POST -H "$auth_header" -H 'Content-Type: application/json' --data "$repo_payload" "$api/user/repos" >/dev/null
          fi

          hook_id="$(${lib.getExe' pkgs.curl "curl"} -fsS -H "$auth_header" "$api/repos/${cfg.repositoryOwner}/${cfg.repositoryName}/hooks" \
            | ${lib.getExe' pkgs.jq "jq"} -r --arg url "$hook_url" '.[] | select(.config.url == $url) | .id' \
            | ${lib.getExe' pkgs.coreutils "head"} -n 1)"

          if [ -z "$hook_id" ]; then
            hook_payload="$(${lib.getExe' pkgs.jq "jq"} -cn \
              --arg url "$hook_url" \
              '{type:"forgejo", config:{url:$url, content_type:"json"}, events:["push"], active:true}')"
            ${lib.getExe' pkgs.curl "curl"} -fsS -X POST -H "$auth_header" -H 'Content-Type: application/json' --data "$hook_payload" "$api/repos/${cfg.repositoryOwner}/${cfg.repositoryName}/hooks" >/dev/null
          fi
        '';
      };

      fava = {
        description = "Fava Beancount web UI";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "fava-ledger-init.service"
        ];
        requires = [ "fava-ledger-init.service" ];
        script = ''
          exec ${getExe cfg.package} \
            --host ${cfg.host} \
            --port ${toString cfg.port} \
            ${lib.optionalString cfg.readOnly "--read-only"} \
            ${cfg.ledgerFile}
        '';
        serviceConfig = {
          User = "fava";
          Group = "fava";
          Restart = "always";
          RestartSec = "10s";
          WorkingDirectory = cfg.dataDir;
        };
      };

      oauth2-proxy-fava = mkIf oidcEnabled {
        description = "oauth2-proxy for Fava";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "kanidm.service"
          "fava.service"
          "fava-oauth2-secrets.service"
        ];
        requires = [
          "kanidm.service"
          "fava.service"
          "fava-oauth2-secrets.service"
        ];
        script = ''
          exec ${getExe pkgs.oauth2-proxy} \
            --provider=oidc \
            --oidc-issuer-url=https://${kanidm.hostName}/oauth2/openid/fava \
            --client-id=fava \
            --http-address=http://${cfg.host}:${toString cfg.authProxy.port} \
            --redirect-url=https://${cfg.hostName}/oauth2/callback \
            --upstream=http://${cfg.host}:${toString cfg.port}/ \
            --scope="openid email profile" \
            --email-domain="*" \
            --reverse-proxy=true \
            --cookie-secure=true \
            --cookie-name=_fava_oauth2_proxy \
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

    services.webhook = {
      enable = lib.mkDefault true;
      ip = lib.mkDefault "127.0.0.1";
      port = lib.mkDefault cfg.webhookPort;
      user = lib.mkDefault "root";
      group = lib.mkDefault "root";
      hooks.deploy-ledger = {
        execute-command = "${deployScript}";
        response-message = "ledger deploy triggered";
      };
    };
  };
}
