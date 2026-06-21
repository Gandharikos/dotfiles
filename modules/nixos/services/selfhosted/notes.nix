{
  config,
  lib,
  pkgs,
  ...
}:
let
  selfhosted = config.dot.selfhosted;
  cfg = selfhosted.services.notes;
  forgejo = selfhosted.services.forgejo;
  defaultPackage = pkgs.runCommand "johnson-notes" { } ''
    mkdir -p "$out"
    cat > "$out/index.html" <<'EOF'
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Johnson Notes</title>
      </head>
      <body>
        <main>
          <h1>Johnson Notes</h1>
          <p>Push Quartz content to public-notes to deploy this site.</p>
        </main>
      </body>
    </html>
    EOF
  '';
  redirectScheme = if selfhosted.useHttps then "https" else "http";
  virtualHostName = host: if selfhosted.useHttps then host else "http://${host}";
  deployScript = pkgs.writeShellScript "selfhosted-notes-deploy" ''
    set -eu

    umask 0022
    export HOME=${cfg.stateDir}
    source_dir=${cfg.stateDir}/source
    worktree_dir=${cfg.stateDir}/worktree
    public_next=${cfg.stateDir}/public-next
    git_safe="${pkgs.git}/bin/git -c safe.directory=$source_dir"

    install -d -m 0755 ${cfg.stateDir} ${cfg.publicDir}

    if ${pkgs.git}/bin/git ls-remote ${cfg.repositoryUrl} HEAD >/dev/null 2>&1; then
      if [ ! -d "$source_dir" ]; then
        ${pkgs.git}/bin/git clone --mirror ${cfg.repositoryUrl} "$source_dir"
      else
        $git_safe -C "$source_dir" remote set-url origin ${cfg.repositoryUrl}
        $git_safe -C "$source_dir" remote update --prune
      fi

      rm -rf "$worktree_dir" "$public_next"
      $git_safe --git-dir "$source_dir" worktree add --force "$worktree_dir" ${cfg.branch}
      trap '$git_safe --git-dir "$source_dir" worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true' EXIT

      if [ -e "$worktree_dir/package.json" ]; then
        cd "$worktree_dir"
        if [ -e pnpm-lock.yaml ]; then
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile
        else
          ${pkgs.pnpm}/bin/pnpm install
        fi

        if ${pkgs.pnpm}/bin/pnpm exec quartz build --output "$public_next"; then
          :
        else
          ${pkgs.pnpm}/bin/pnpm exec quartz build
          if [ -d public ]; then
            cp -a public "$public_next"
          else
            echo "Quartz build did not produce public output" >&2
            exit 1
          fi
        fi
      else
        rm -rf "$public_next"
        install -d -m 0755 "$public_next"
        cp -a ${cfg.package}/. "$public_next/"
      fi

      rm -rf ${cfg.publicDir}
      mv "$public_next" ${cfg.publicDir}
    elif [ ! -e ${cfg.publicDir}/index.html ]; then
      rm -rf "$public_next"
      install -d -m 0755 "$public_next"
      cp -a ${cfg.package}/. "$public_next/"
      rm -rf ${cfg.publicDir}
      mv "$public_next" ${cfg.publicDir}
    fi
  '';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    int
    package
    str
    ;
in
{
  options.dot.selfhosted.services.notes = {
    enable = mkEnableOption "Quartz notes" // {
      default = false;
    };

    package = mkOption {
      type = package;
      default = defaultPackage;
      description = "Fallback static notes package.";
    };

    subdomain = mkOption {
      type = str;
      default = "notes";
      description = "Subdomain used by the notes site.";
    };

    hostName = mkOption {
      type = str;
      default = "${cfg.subdomain}.${selfhosted.domain}";
      description = "Host name used by the notes site.";
    };

    stateDir = mkOption {
      type = str;
      default = "/var/lib/selfhosted-notes";
      description = "State directory used for notes deployment.";
    };

    publicDir = mkOption {
      type = str;
      default = "${cfg.stateDir}/public";
      description = "Directory served by the reverse proxy.";
    };

    repositoryOwner = mkOption {
      type = str;
      default = config.dot.primaryUser;
      description = "Forgejo owner used for the notes repository.";
    };

    repositoryName = mkOption {
      type = str;
      default = "public-notes";
      description = "Forgejo repository name used for the Quartz source.";
    };

    repositoryUrl = mkOption {
      type = str;
      default = "http://${forgejo.host}:${toString forgejo.port}/${cfg.repositoryOwner}/${cfg.repositoryName}.git";
      description = "Git URL used by the deploy hook to fetch Quartz content.";
    };

    branch = mkOption {
      type = str;
      default = "main";
      description = "Branch deployed to the public notes site.";
    };

    webhookPort = mkOption {
      type = int;
      default = 9010;
      description = "Local port used by Forgejo to trigger notes deployment.";
    };
  };

  config = mkIf cfg.enable {
    dot.selfhosted.services.gatus.endpoints = [
      {
        name = "notes";
        url = "${redirectScheme}://${cfg.hostName}";
        interval = "1m";
        conditions = [ "[STATUS] == 200" ];
      }
    ];

    users.users.selfhosted-notes = {
      isSystemUser = true;
      group = "selfhosted-notes";
      home = cfg.stateDir;
      createHome = true;
    };
    users.groups.selfhosted-notes = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 selfhosted-notes selfhosted-notes - -"
      "d ${cfg.publicDir} 0755 selfhosted-notes selfhosted-notes - -"
    ];

    systemd.services.selfhosted-notes-deploy = {
      description = "Deploy the self-hosted Quartz notes";
      after = lib.optional forgejo.enable "forgejo.service";
      wants = lib.optional forgejo.enable "forgejo.service";
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.git
        pkgs.nodejs
        pkgs.pnpm
      ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = "${deployScript}";
    };

    systemd.services.selfhosted-notes-forgejo = mkIf forgejo.enable {
      description = "Create Forgejo notes repository and deploy webhook";
      after = [ "forgejo.service" ];
      requires = [ "forgejo.service" ];
      before = [ "selfhosted-notes-deploy.service" ];
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

        forgejo='${lib.getExe config.services.forgejo.package}'
        config_file='${config.services.forgejo.customDir}/conf/app.ini'
        work_path='${config.services.forgejo.stateDir}'
        credential_dir='${config.services.forgejo.stateDir}/selfhosted-notes'
        password_file="$credential_dir/${cfg.repositoryOwner}-password"
        token_file="$credential_dir/${cfg.repositoryOwner}-bootstrap-token"
        api='http://${forgejo.host}:${toString forgejo.port}/api/v1'
        hook_url='http://127.0.0.1:${toString cfg.webhookPort}/hooks/deploy-notes'

        install -d -m 0700 "$credential_dir"

        if ! "$forgejo" admin user list --config "$config_file" --work-path "$work_path" \
          | ${pkgs.gawk}/bin/awk 'NR > 1 && $2 == "${cfg.repositoryOwner}" { found = 1 } END { exit !found }'
        then
          if [ ! -s "$password_file" ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 24 > "$password_file"
            chmod 0600 "$password_file"
          fi

          "$forgejo" admin user create \
            --config "$config_file" \
            --work-path "$work_path" \
            --username ${cfg.repositoryOwner} \
            --password "$(${pkgs.coreutils}/bin/cat "$password_file")" \
            --email ${config.dot.admin.email} \
            --admin \
            --must-change-password=false
        fi

        if [ ! -s "$token_file" ]; then
          "$forgejo" admin user generate-access-token \
            --config "$config_file" \
            --work-path "$work_path" \
            --username ${cfg.repositoryOwner} \
            --token-name selfhosted-notes-bootstrap \
            --scopes write:user,write:repository,read:user \
            --raw > "$token_file"
          chmod 0600 "$token_file"
        fi

        token="$(${pkgs.coreutils}/bin/cat "$token_file")"
        auth_header="Authorization: token $token"

        repo_status="$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' -H "$auth_header" "$api/repos/${cfg.repositoryOwner}/${cfg.repositoryName}")"
        if [ "$repo_status" = 404 ]; then
          repo_payload="$(${pkgs.jq}/bin/jq -cn \
            --arg name ${cfg.repositoryName} \
            --arg branch ${cfg.branch} \
            '{name:$name, private:false, auto_init:true, default_branch:$branch, description:"Quartz source for notes.huwenqiang.dev"}')"
          ${pkgs.curl}/bin/curl -fsS -X POST -H "$auth_header" -H 'Content-Type: application/json' --data "$repo_payload" "$api/user/repos" >/dev/null
        fi

        hook_id="$(${pkgs.curl}/bin/curl -fsS -H "$auth_header" "$api/repos/${cfg.repositoryOwner}/${cfg.repositoryName}/hooks" \
          | ${pkgs.jq}/bin/jq -r --arg url "$hook_url" '.[] | select(.config.url == $url) | .id' \
          | ${pkgs.coreutils}/bin/head -n 1)"

        if [ -z "$hook_id" ]; then
          hook_payload="$(${pkgs.jq}/bin/jq -cn \
            --arg url "$hook_url" \
            '{type:"forgejo", config:{url:$url, content_type:"json"}, events:["push"], active:true}')"
          ${pkgs.curl}/bin/curl -fsS -X POST -H "$auth_header" -H 'Content-Type: application/json' --data "$hook_payload" "$api/repos/${cfg.repositoryOwner}/${cfg.repositoryName}/hooks" >/dev/null
        fi
      '';
    };

    services.webhook = {
      enable = lib.mkDefault true;
      ip = lib.mkDefault "127.0.0.1";
      port = lib.mkDefault cfg.webhookPort;
      user = lib.mkDefault "root";
      group = lib.mkDefault "root";
      hooks.deploy-notes = {
        execute-command = "${deployScript}";
        response-message = "notes deploy triggered";
      };
    };

    services.caddy.virtualHosts = mkIf selfhosted.services.caddy.enable {
      ${virtualHostName cfg.hostName}.extraConfig = ''
        encode zstd gzip
        root * ${cfg.publicDir}
        file_server
      '';
    };

    services.nginx.virtualHosts = mkIf selfhosted.services.nginx.enable {
      ${cfg.hostName} = {
        enableACME = selfhosted.useHttps;
        forceSSL = selfhosted.useHttps;
        root = cfg.publicDir;
      };
    };
  };
}
