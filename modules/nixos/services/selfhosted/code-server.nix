{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.code-server;
  passwordEnv = "${cfg.stateDir}/password-env";
  inherit (lib) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    listOf
    package
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
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.code-server = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      gatus.endpoints = [ (lib.dot.mkGatusEndpoint "code-server" cfg) ];
      backups.paths = [ cfg.stateDir ];
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
        group = "code-server";
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
      code-server-password = {
        description = "Generate code-server password";
        before = [ "code-server.service" ];
        requiredBy = [ "code-server.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o code-server -g code-server ${cfg.stateDir}
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
            --auth password \
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
    };
  };
}
