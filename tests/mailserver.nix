let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  host = flake.nixosConfigurations.athena;
  direct = host.config;
  relay =
    (host.extendModules {
      modules = [
        ({ lib, ... }: {
          dot.selfhosted.services.mailserver.delivery.mode = lib.mkForce "relay";
        })
      ];
    }).config;
in
{
  directDelivery =
    assert direct.dot.selfhosted.services.mailserver.delivery.mode == "direct";
    assert direct.services.postfix.settings.main.relayhost == [ ];
    assert !(direct.services.postfix.settings.main.smtp_sasl_auth_enable or false);
    assert !(direct.sops.secrets ? mailserver-relay-password);
    assert !(direct.systemd.services ? postfix-relay-setup);
    true;
  directTls =
    assert direct.services.resolved.enable;
    assert direct.services.resolved.settings.Resolve.DNSSEC == true;
    assert direct.services.postfix.settings.main.smtp_tls_security_level == "dane";
    assert direct.services.postfix.settings.main.smtp_dns_support_level == "dnssec";
    assert direct.services.postfix.settings.main.smtp_tls_protocols == ">=TLSv1.2";
    assert direct.services.postfix.settings.main.smtpd_tls_auth_only;
    assert direct.mailserver.enableSubmissionSsl;
    assert direct.mailserver.dkim.enable;
    assert builtins.elem "--reuse-key"
      direct.security.acme.certs."mx.huwenqiang.dev".extraLegoRenewFlags;
    true;
  relayDelivery =
    assert relay.services.postfix.settings.main.relayhost == [ "[mail.smtp2go.com]:587" ];
    assert relay.services.postfix.settings.main.smtp_sasl_auth_enable;
    assert relay.services.postfix.settings.main.smtp_tls_security_level == "encrypt";
    assert relay.sops.secrets ? mailserver-relay-password;
    assert relay.systemd.services ? postfix-relay-setup;
    true;
}
