---
title: Mailserver
description: Direct SMTP delivery, SMTP2GO fallback, DKIM and TLS checks on Athena.
---

Athena hosts mail for `huwenqiang.dev` at `mx.huwenqiang.dev`. Postfix handles SMTP, Dovecot stores
mail and serves IMAP, and Rspamd signs outbound mail with DKIM.

## Account secrets

Mailbox credentials, including `jobs` and `signup`, are stored in `secrets/services/mailserver.yaml`
under their account-name keys. The separate `mailserver-accounts.yaml` file has been merged into it
without changing passwords or encryption recipients. Runtime secret names and paths remain
unchanged. Keep all credentials SOPS-encrypted; do not include decrypted values in logs, command
arguments, documentation, or commits.

## Delivery mode

Set `dot.selfhosted.services.mailserver.delivery.mode` to `"direct"` or `"relay"`. Athena selects
`direct`. This delivers to recipient MX servers over TCP 25. `relay` uses the existing
`delivery.relay` settings and SOPS password on port 587. The encrypted credential and fallback
settings remain available in the repository; direct mode does not install the relay secret or
credential setup service. Switching modes requires a rebuild and activation; there is no automatic
fallback.

For rollback to the relay, change only the mode to `"relay"`, build, and deploy. Do not remove the
encrypted relay credential until the fallback is no longer needed.

## DNS and transport security

- MX: `huwenqiang.dev` → `mx.huwenqiang.dev`.
- A: `159.69.182.58`; AAAA: `2a01:4f8:c015:cfa3::1`.
- Both addresses must have PTR `mx.huwenqiang.dev`.
- SPF: `v=spf1 mx -all` authorizes direct sending from the MX addresses.
- DKIM selector: `mail`; public record: `mail._domainkey.huwenqiang.dev`.
- DMARC currently uses monitoring policy `p=none`.

Direct delivery inherits the pinned mailserver's `dane` TLS policy and DNSSEC support, plus its
Postfix TLS policy service. DANE without authenticated TLSA records can fall back to opportunistic
TLS; this is not a promise of encryption to every destination. Relay mode explicitly requires TLS
(`encrypt`). Both modes retain the upstream TLS 1.2 minimum. Client submission uses implicit TLS on
port 465; inbound server-to-server SMTP offers STARTTLS on port 25. Authentication requires TLS.

Athena enables strict DNSSEC validation in systemd-resolved with
`services.resolved.settings.Resolve.DNSSEC = true`. Its existing upstream resolvers remain in use;
Postfix and the TLS policy service query the local stub. Invalid signatures must fail resolution,
while unsigned domains remain usable. This validates outbound lookups; domain signing and inbound
TLSA publication are managed separately in Cloudflare. Other hosts retain their resolver settings.

The DKIM private key stays under `/var/lib/mailserver/dkim`, owned by Rspamd. Compare its derived
public key with DNS without printing or copying the private key. Do not regenerate this key as part
of a delivery-mode change.

## Inbound DANE

Cloudflare is both the registrar and authoritative DNS provider for `huwenqiang.dev`. DNSSEC must be
enabled there, with its DS record published in the `.dev` parent zone. A signed TLSA record alone is
insufficient: validating resolvers must authenticate the entire delegation chain.

The SMTP record published on 2026-11-09 is:

```dns
_25._tcp.mx.huwenqiang.dev. 300 IN TLSA 3 1 1 e6818a861ccb797660ea6293cba8f107fbdcd24490bba86f19e993b37708e10a
```

This pins the SHA-256 digest of the leaf certificate's SubjectPublicKeyInfo for inbound SMTP on
port 25. Both IPv4 and IPv6 must serve a certificate with that public key. It is independent of the
DKIM signing key and does not cover submission or IMAPS ports.

Athena sets `security.acme.certs."mx.huwenqiang.dev".extraLegoRenewFlags = [ "--reuse-key" ]` so
routine ACME renewal preserves this pin. Initial activation changed ACME's state directory and
issued a new certificate; the record above was published only after confirming the new public key on
the live SMTP endpoint. A subsequent renewal check used `--reuse-key`, skipped renewal because the
certificate was not due, and left the key unchanged. This is not a forced renewal test.

Before intentional key rotation, publish both old and new TLSA digests, wait at least the old
record's TTL, then deploy the new key and verify both address families. Keep the old record during
the rollback window before removing it. Changes that recreate ACME's state directory, certificate
recovery, or forced initial issuance also require this coordination: renewal key reuse alone does
not protect those paths. Do not roll back to a different key while only the new pin is published.

The deployment source is `/var/tmp/athena-dane-inbound-20261109` on Athena; the previous generation
is retained at `/nix/var/nix/gcroots/athena-before-inbound-dane-20261109`. This change was built
with Athena's existing dependency lock. External SMTP STARTTLS probes from ymir matched the
published pin over both IPv4 and IPv6 with TLS 1.3. The `.dev` authoritative server published DS
`2371 13 2 94097C4B60E10EDD59B8CEA66D0C640A3F884EF643BE5A7980B39FAB538F4E20`. Google Public DNS and
Athena's validating stub returned the TLSA answer with the authenticated-data flag; Athena's TLS
policy service returned `dane-only` for `huwenqiang.dev`. Some public resolver caches initially
retained the earlier unsigned delegation, so check the AD flag, not just the presence of RRSIG
records, when verifying propagation.

Final checks also confirmed authenticated TLSA answers from Cloudflare (`1.1.1.1`) and Quad9
(`9.9.9.9`). The pinned system build, mail configuration assertions, and `just check` passed.

## Validation

Run `nix eval --impure --json --file tests/mailserver.nix` with the `pipe-operators` experimental
feature, then build the affected host. Before activation, review closure and service changes against
the running system and retain a rollback generation.

After activation, inspect `postconf relayhost smtp_tls_security_level smtp_tls_policy_maps`, check
the certificate hostname/chain on SMTP and IMAPS, and send an explicitly authorized test message.
Confirm direct MX delivery and TLS in Postfix logs, then inspect the received message's SPF, DKIM
and DMARC results. SMTP acceptance alone does not prove inbox placement.

## Verified deployment — 2026-11-09

The mail change was built against Athena's existing source snapshot and dependency lock
(`26.11.20261030.1c89083`) to avoid unrelated upgrades. The repository lock is unchanged. The
deployment source is `/var/tmp/athena-mail-pinned-20261109` on Athena. The previous system is
retained by `/nix/var/nix/gcroots/athena-mail-before-20261109`. Postfix required an explicit restart
after activation to regenerate its runtime configuration; the activation preview listed only the
SOPS service restart.

The DKIM key's derived public key matched DNS. SMTP STARTTLS (25), submission TLS (465), and IMAPS
(993) negotiated TLS 1.3 with a valid certificate for `mx.huwenqiang.dev`. The direct Gmail test
reached the inbox with SPF, DKIM and DMARC passing; Postfix recorded verified TLS 1.3 to Gmail's MX
on port 25. No SMTP2GO relay was used.

The follow-up DNSSEC deployment uses `/var/tmp/athena-dnssec-20261109`, with the preceding direct
mail generation retained at `/nix/var/nix/gcroots/athena-before-dnssec-20261109`. It enables strict
DNSSEC validation without changing DNS ownership or upgrading dependencies. The local stub returns
authenticated answers for `sys4.de`, rejects `dnssec-failed.org` with `SERVFAIL`, and permits that
test domain only when the query explicitly disables checking. The resolver's secure/bogus counters
and validation failure log confirm local validation. `resolvectl show-server-state` reports DNSSEC
mode and support as `yes` for the active upstream; the global status summary still shows
`yes/unsupported`, so that summary alone is not a validation test.

The TLS policy service's old persistent cache was moved to
`/var/cache/postfix-tlspol/cache.before-dnssec-20261109.db` while stopped. Its fresh query for
`sys4.de` returns `dane-only`, replacing the previously cached MTA-STS result. From Athena, an
OpenSSL SMTP STARTTLS probe to `mail.sys4.de` matched the DNSSEC-authenticated TLSA record to the
server certificate. A separate probe with a deliberately incorrect fingerprint failed. These probes
perform handshakes only; no mail is sent to that third party.

After this deployment, Gmail received a second direct test message in the inbox with SPF, DKIM and
DMARC passing (Postfix queue ID `B932B320020`). Postfix logged verified TLS 1.3 to Gmail's MX, with
no DNSSEC-unavailable warning, and the queue emptied. Gmail delivery verifies ordinary TLS and
message authentication; the separate TLSA probes above verify DANE. The repository's `just check`
and the pinned Athena system build passed.

The pre-existing failed units `podman-seafile-memcached.service` and `seafile-oidc-secret.service`
were present before and after activation. They are unrelated to mail delivery.
