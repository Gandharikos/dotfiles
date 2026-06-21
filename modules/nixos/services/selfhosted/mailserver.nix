{
  config,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted.services.mailserver;
  selfhosted = config.dot.selfhosted;
  inherit (selfhosted) domain;
  secretsFile = "${self}/secrets/services/mailserver.yaml";
  acmeWebroot = "/var/lib/acme/acme-challenge";
  relayEnabled = cfg.delivery.mode == "relay";
  relayHost = "[${cfg.delivery.relay.host}]:${toString cfg.delivery.relay.port}";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkForce mkIf mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum port str;
in
{
  imports = [ inputs.simple-nixos-mailserver.nixosModules.default ];

  options.dot.selfhosted.services.mailserver =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "mailserver";
      displayName = "mailserver";
      subdomain = "mail";
      defaultPort = 8088;
      defaultEnable = false;
    }
    // {
      fqdn = mkOption {
        type = str;
        default = "mx.${domain}";
        description = "FQDN used by SMTP and IMAP services.";
      };

      storagePath = mkOption {
        type = str;
        default = "/var/lib/mailserver/vmail";
        description = "Persistent mail storage directory.";
      };

      dkimKeyDirectory = mkOption {
        type = str;
        default = "/var/lib/mailserver/dkim";
        description = "Directory where DKIM keys are stored.";
      };

      delivery = {
        mode = mkOption {
          type = enum [
            "direct"
            "relay"
          ];
          default = "direct";
          description = "Outbound delivery mode. Use relay when the VPS provider blocks outbound SMTP port 25.";
        };

        relay = {
          host = mkOption {
            type = str;
            default = "";
            example = "mail.smtp2go.com";
            description = "SMTP relay host used when delivery.mode is relay.";
          };

          port = mkOption {
            type = port;
            default = 587;
            description = "SMTP relay port.";
          };

          username = mkOption {
            type = str;
            default = "";
            description = "SMTP relay username.";
          };

          passwordSecretKey = mkOption {
            type = str;
            default = "relay-password";
            description = "Key in secrets/services/mailserver.yaml containing the SMTP relay password.";
          };
        };
      };
    };

  config = mkMerge [
    {
      # Avoid an eval-time null coercion in simple-nixos-mailserver defaults.
      mailserver.quota.enable = false;
    }

    (mkIf cfg.enable {
      dot.selfhosted.services.postgresql.enable = true;

      sops.secrets = {
        mailserver-johnson = {
          sopsFile = secretsFile;
          key = "johnson";
        };
        mailserver-git = {
          sopsFile = secretsFile;
          key = "git";
        };
        mailserver-vaultwarden = {
          sopsFile = secretsFile;
          key = "vaultwarden";
        };
        mailserver-noreply = {
          sopsFile = secretsFile;
          key = "noreply";
        };
        mailserver-spam = {
          sopsFile = secretsFile;
          key = "spam";
        };
      }
      // optionalAttrs relayEnabled {
        mailserver-relay-password = {
          sopsFile = secretsFile;
          key = cfg.delivery.relay.passwordSecretKey;
        };
      };

      mailserver = {
        enable = true;
        openFirewall = true;
        stateVersion = 5;

        inherit (cfg) fqdn;
        domains = [ domain ];
        localDnsResolver = false;
        hierarchySeparator = "/";

        storage = {
          directoryLayout = "fs";
          owner = "vmail";
          group = "vmail";
          path = cfg.storagePath;
        };

        enableImap = true;
        enableImapSsl = true;
        enablePop3 = false;
        enablePop3Ssl = false;
        enableSubmission = false;
        enableSubmissionSsl = true;
        enableManageSieve = true;

        dkim = {
          defaults.keyLength = 4096;
          keyDirectory = cfg.dkimKeyDirectory;
        };

        x509.useACMEHost = cfg.fqdn;
        rejectRecipients = [ "noreply@${domain}" ];

        accounts = {
          "johnson@${domain}" = {
            passwordFile = config.sops.secrets.mailserver-johnson.path;
            aliases = [
              "johnson"
              "admin"
              "admin@${domain}"
              "me"
              "me@${domain}"
              "root"
              "root@${domain}"
              "postmaster"
              "postmaster@${domain}"
            ];
          };

          "git@${domain}" = {
            passwordFile = config.sops.secrets.mailserver-git.path;
            aliases = [
              "git"
              "forgejo"
              "forgejo@${domain}"
            ];
          };

          "vaultwarden@${domain}" = {
            passwordFile = config.sops.secrets.mailserver-vaultwarden.path;
            aliases = [
              "vaultwarden"
              "bitwarden"
              "bitwarden@${domain}"
            ];
          };

          "noreply@${domain}" = {
            passwordFile = config.sops.secrets.mailserver-noreply.path;
            aliases = [ "noreply" ];
          };

          "spam@${domain}" = {
            passwordFile = config.sops.secrets.mailserver-spam.path;
            aliases = [
              "spam"
              "bot"
              "bot@${domain}"
            ];
          };
        };

        mailboxes = {
          Archive = {
            auto = "subscribe";
            special_use = "\\Archive";
          };
          Drafts = {
            auto = "subscribe";
            special_use = "\\Drafts";
          };
          Sent = {
            auto = "subscribe";
            special_use = "\\Sent";
          };
          Junk = {
            auto = "subscribe";
            special_use = "\\Junk";
          };
          Trash = {
            auto = "subscribe";
            special_use = "\\Trash";
          };
        };

        fullTextSearch = {
          enable = true;
          autoIndex = true;
          fallback = false;
        };
      };

      services = {
        roundcube = {
          enable = true;
          inherit (cfg) hostName;
          package = pkgs.roundcube.withPlugins (
            plugins: with plugins; [
              carddav
              persistent_login
            ]
          );
          maxAttachmentSize = config.mailserver.messageSizeLimit / 1024 / 1024;
          dicts = with pkgs.aspellDicts; [ en ];
          plugins = [
            "carddav"
            "managesieve"
            "persistent_login"
          ];
          extraConfig = ''
            $config['imap_host'] = "ssl://${config.mailserver.fqdn}";
            $config['smtp_host'] = "ssl://${config.mailserver.fqdn}";
            $config['smtp_user'] = "%u";
            $config['smtp_pass'] = "%p";
            $config['managesieve_host'] = "tls://${config.mailserver.fqdn}";
            $config['managesieve_port'] = 4190;
            $config['managesieve_usetls'] = true;
            $config['username_domain'] = "${domain}";
          '';
        };

        nginx.virtualHosts.${cfg.hostName} = mkIf config.dot.selfhosted.services.caddy.enable {
          forceSSL = false;
          enableACME = false;
          listen = [
            {
              addr = cfg.host;
              inherit (cfg) port;
            }
          ];
        };

        caddy.virtualHosts.${cfg.hostName} = mkIf config.dot.selfhosted.services.caddy.enable {
          extraConfig = ''
            encode zstd gzip
            reverse_proxy ${cfg.host}:${toString cfg.port}
          '';
        };

        caddy.virtualHosts."http://${cfg.fqdn}" = mkIf config.dot.selfhosted.services.caddy.enable {
          extraConfig = ''
            root * ${acmeWebroot}
            file_server
          '';
        };

        phpfpm.pools.roundcube.settings = {
          "listen.owner" = config.services.nginx.user;
          "listen.group" = config.services.nginx.group;
        };

        postfix.settings.main = {
          smtp_helo_name = config.mailserver.fqdn;
        }
        // optionalAttrs relayEnabled {
          relayhost = [ relayHost ];
          smtp_sasl_auth_enable = true;
          smtp_sasl_password_maps = [ "hash:/etc/postfix/sasl_passwd" ];
          smtp_sasl_security_options = "noanonymous";
          smtp_tls_security_level = mkForce "encrypt";
        };
      };

      assertions = [
        {
          assertion = !relayEnabled || cfg.delivery.relay.host != "";
          message = "dot.selfhosted.services.mailserver.delivery.relay.host must be set when delivery.mode is relay.";
        }
        {
          assertion = !relayEnabled || cfg.delivery.relay.username != "";
          message = "dot.selfhosted.services.mailserver.delivery.relay.username must be set when delivery.mode is relay.";
        }
      ];

      systemd.services.postfix-relay-setup = mkIf relayEnabled {
        description = "Setup Postfix SMTP relay credentials";
        requiredBy = [ "postfix.service" ];
        requires = [
          "postfix-setup.service"
          "sops-install-secrets.service"
        ];
        after = [
          "postfix-setup.service"
          "sops-install-secrets.service"
        ];
        before = [ "postfix.service" ];
        path = [ config.services.postfix.package ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          set -euo pipefail

          install -d -m 0755 -o root -g root /var/lib/postfix/conf
          umask 077
          {
            printf '%s %s:' '${relayHost}' '${cfg.delivery.relay.username}'
            cat ${config.sops.secrets.mailserver-relay-password.path}
            printf '\n'
          } > /var/lib/postfix/conf/sasl_passwd

          postmap /var/lib/postfix/conf/sasl_passwd
          chown root:root /var/lib/postfix/conf/sasl_passwd /var/lib/postfix/conf/sasl_passwd.db
          chmod 0600 /var/lib/postfix/conf/sasl_passwd /var/lib/postfix/conf/sasl_passwd.db
        '';
      };

      systemd.services.postfix-setup.serviceConfig.RemainAfterExit = mkForce false;

      security.acme = {
        acceptTerms = true;
        defaults.email = config.dot.admin.email;
        certs.${cfg.fqdn}.webroot = acmeWebroot;
      };

      systemd.tmpfiles.settings.selfhosted-mailserver = {
        ${acmeWebroot}.d = {
          user = "root";
          group = "root";
          mode = "0755";
        };
        ${cfg.storagePath}.d = {
          user = "vmail";
          group = "vmail";
          mode = "0700";
        };
        ${cfg.dkimKeyDirectory}.d = {
          user = "rspamd";
          group = "rspamd";
          mode = "0700";
        };
        "/var/lib/postfix/conf".d = {
          user = "root";
          group = "root";
          mode = "0755";
        };
      };
    })
  ];
}
