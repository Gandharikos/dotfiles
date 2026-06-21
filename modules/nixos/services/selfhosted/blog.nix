{
  config,
  lib,
  pkgs,
  ...
}:
let
  selfhosted = config.dot.selfhosted;
  cfg = selfhosted.services.blog;
  forgejo = selfhosted.services.forgejo;
  blowfish = pkgs.fetchFromGitHub {
    owner = "nunocoracao";
    repo = "blowfish";
    rev = "v2.103.0";
    hash = "sha256-mf00ZdWC9hZj+JOyeJcGFILXkYwjIQegLYc+ACSx1H0=";
  };
  blogSource = pkgs.runCommand "johnson-blog-source" { } ''
        mkdir -p "$out/themes/blowfish" "$out/content/posts"
        cp -a ${blowfish}/. "$out/themes/blowfish/"

        cat > "$out/hugo.toml" <<'EOF'
    baseURL = "${redirectScheme}://${cfg.hostName}/"
    languageCode = "en"
    title = "Johnson Hu"
    theme = "blowfish"
    enableRobotsTXT = true
    summaryLength = 30

    [params]
      colorScheme = "blowfish"
      defaultAppearance = "light"
      autoSwitchAppearance = true
      description = "Personal notes and long-form writing."

    [params.author]
      name = "Johnson Hu"
      headline = "Notes, systems, and software."

    [menus]
      [[menus.main]]
        name = "Posts"
        pageRef = "posts"
        weight = 10
    EOF

        cat > "$out/content/_index.md" <<'EOF'
    +++
    title = "Johnson Hu"
    +++

    Welcome.
    EOF

        cat > "$out/content/posts/_index.md" <<'EOF'
    +++
    title = "Posts"
    +++
    EOF

        cat > "$out/content/posts/hello.md" <<'EOF'
    +++
    title = "Hello"
    date = 2026-06-21
    draft = false
    +++

    This blog is built with Hugo and the Blowfish theme.
    EOF
  '';
  defaultPackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "johnson-blog";
    version = "2026-06-21";
    src = blogSource;
    nativeBuildInputs = [ pkgs.hugo ];
    buildPhase = ''
      runHook preBuild
      hugo --minify --destination public
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -a public/. "$out/"
      runHook postInstall
    '';
  };
  virtualHostName = host: if selfhosted.useHttps then host else "http://${host}";
  redirectScheme = if selfhosted.useHttps then "https" else "http";
  redirectHosts = lib.filter (host: host != cfg.hostName) cfg.redirectHostNames;
  deployScript = pkgs.writeShellScript "selfhosted-blog-deploy" ''
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

      if [ ! -e "$worktree_dir/hugo.toml" ] && [ ! -e "$worktree_dir/config.toml" ] && [ ! -e "$worktree_dir/config.yaml" ] && [ ! -e "$worktree_dir/config/_default/hugo.toml" ]; then
        cp ${blogSource}/hugo.toml "$worktree_dir/hugo.toml"
      fi

      if [ ! -d "$worktree_dir/content" ]; then
        cp -a ${blogSource}/content "$worktree_dir/content"
      fi

      if [ ! -d "$worktree_dir/themes/blowfish" ]; then
        install -d "$worktree_dir/themes"
        ln -s ${blowfish} "$worktree_dir/themes/blowfish"
      fi

      ${pkgs.hugo}/bin/hugo --source "$worktree_dir" --destination "$public_next" --minify --baseURL ${redirectScheme}://${cfg.hostName}/
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
  inherit (lib.attrsets) genAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    int
    listOf
    package
    str
    ;
in
{
  options.dot.selfhosted.services.blog = {
    enable = mkEnableOption "Hugo blog" // {
      default = false;
    };

    package = mkOption {
      type = package;
      default = defaultPackage;
      description = "Built Hugo blog package.";
    };

    subdomain = mkOption {
      type = str;
      default = "blog";
      description = "Subdomain used by the blog.";
    };

    hostName = mkOption {
      type = str;
      default = "${cfg.subdomain}.${selfhosted.domain}";
      description = "Host name used by the blog.";
    };

    redirectHostNames = mkOption {
      type = listOf str;
      default = [
        selfhosted.domain
        "www.${selfhosted.domain}"
      ];
      description = "Host names redirected to the blog.";
    };

    stateDir = mkOption {
      type = str;
      default = "/var/lib/selfhosted-blog";
      description = "State directory used for blog deployment.";
    };

    publicDir = mkOption {
      type = str;
      default = "${cfg.stateDir}/public";
      description = "Directory served by the reverse proxy.";
    };

    repositoryOwner = mkOption {
      type = str;
      default = config.dot.primaryUser;
      description = "Forgejo owner used for the blog repository.";
    };

    repositoryName = mkOption {
      type = str;
      default = "blog";
      description = "Forgejo repository name used for the blog source.";
    };

    repositoryUrl = mkOption {
      type = str;
      default = "http://${forgejo.host}:${toString forgejo.port}/${cfg.repositoryOwner}/${cfg.repositoryName}.git";
      description = "Git URL used by the deploy hook to fetch blog content.";
    };

    branch = mkOption {
      type = str;
      default = "main";
      description = "Branch deployed to the public blog.";
    };

    webhookPort = mkOption {
      type = int;
      default = 9010;
      description = "Local port used by Forgejo to trigger blog deployment.";
    };
  };

  config = mkIf cfg.enable {
    dot.selfhosted.services.gatus.endpoints = [
      {
        name = "blog";
        url = "${redirectScheme}://${cfg.hostName}";
        interval = "1m";
        conditions = [ "[STATUS] == 200" ];
      }
    ];

    users.users.selfhosted-blog = {
      isSystemUser = true;
      group = "selfhosted-blog";
      home = cfg.stateDir;
      createHome = true;
    };
    users.groups.selfhosted-blog = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 selfhosted-blog selfhosted-blog - -"
      "d ${cfg.publicDir} 0755 selfhosted-blog selfhosted-blog - -"
    ];

    systemd.services.selfhosted-blog-deploy = {
      description = "Deploy the self-hosted Hugo blog";
      after = lib.optional forgejo.enable "forgejo.service";
      wants = lib.optional forgejo.enable "forgejo.service";
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.git
        pkgs.hugo
      ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = "${deployScript}";
    };

    systemd.services.selfhosted-blog-forgejo = mkIf forgejo.enable {
      description = "Create Forgejo blog repository and deploy webhook";
      after = [ "forgejo.service" ];
      requires = [ "forgejo.service" ];
      before = [ "selfhosted-blog-deploy.service" ];
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
        credential_dir='${config.services.forgejo.stateDir}/selfhosted-blog'
        password_file="$credential_dir/${cfg.repositoryOwner}-password"
        token_file="$credential_dir/${cfg.repositoryOwner}-bootstrap-token"
        api='http://${forgejo.host}:${toString forgejo.port}/api/v1'
        hook_url='http://127.0.0.1:${toString cfg.webhookPort}/hooks/deploy-blog'

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
            --token-name selfhosted-blog-bootstrap \
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
            '{name:$name, private:false, auto_init:true, default_branch:$branch, description:"Hugo source for blog.huwenqiang.dev"}')"
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
      enable = true;
      ip = "127.0.0.1";
      port = cfg.webhookPort;
      user = "root";
      group = "root";
      hooks.deploy-blog = {
        execute-command = "${deployScript}";
        response-message = "blog deploy triggered";
      };
    };

    services.caddy.virtualHosts = mkIf selfhosted.services.caddy.enable (
      {
        ${virtualHostName cfg.hostName}.extraConfig = ''
          encode zstd gzip
          root * ${cfg.publicDir}
          file_server
        '';
      }
      // genAttrs (map virtualHostName redirectHosts) (_: {
        extraConfig = ''
          redir ${redirectScheme}://${cfg.hostName}{uri} permanent
        '';
      })
    );

    services.nginx.virtualHosts = mkIf selfhosted.services.nginx.enable (
      {
        ${cfg.hostName} = {
          enableACME = selfhosted.useHttps;
          forceSSL = selfhosted.useHttps;
          root = cfg.publicDir;
        };
      }
      // genAttrs redirectHosts (_: {
        enableACME = selfhosted.useHttps;
        forceSSL = selfhosted.useHttps;
        locations."/".extraConfig = ''
          return 301 ${redirectScheme}://${cfg.hostName}$request_uri;
        '';
      })
    );
  };
}
