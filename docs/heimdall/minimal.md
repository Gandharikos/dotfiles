# Heimdall: minimal host only

The worktree retains only the verified N150 hardware, Disko ext4/EFI layout (no disk swap),
systemd-boot, zram, the johnson user, shared SSH settings, and networkd management at
`192.168.8.2/24`. Its default route and DNS point to Flint `192.168.8.1`. NetworkManager, IPv6
forwarding, NAT and proxy are disabled. Tailscale is enabled as a plain client with autoconnect,
using the shared SOPS-managed auth key from `secrets/services/tailscale.yaml` when enrollment is
needed. It does not accept DNS or subnet routes. It inherits the shared `--ssh` flag, enabling
Tailscale SSH. No subnet routes are declared; previously saved advertisements are not explicitly
cleared. Heimdall explicitly sets `exitNode = ""` to clear any saved exit-node selection and use its
own default route. The shared default remains `null` (unmanaged); other hosts are unchanged. OpenSSH
inherits the global ports 22 and 2222; Tailnet traffic still passes the host firewall rather than
gaining blanket interface trust. With Tailscale SSH enabled, use port 2222 for ordinary OpenSSH
through the Tailnet address.

The dedicated `.sops.yaml` rule grants Heimdall access only to `secrets/services/tailscale.yaml`,
not to other shared service secrets. Its encrypted recipients were updated without changing the
encrypted payload, and decryption was verified on Heimdall. Preserve the on-disk Tailscale identity.

No DHCP server, OliveTin panel, gateway health service or gateway release machinery is imported.
Keep the SSH key and existing Tailscale identity/state on the machine.

`hosts/heimdall/hardware-configuration.nix` is generated on the physical host using
`nixos-generate-config --show-hardware-config --no-filesystems`, then formatted with nixfmt.
Filesystem declarations remain owned by Disko. The verified disk path and management NIC MAC are
specified directly in `config.nix`; there is no `dot.hardware.heimdall` option layer or confirmation
flag. Generating this file reads hardware only; it does not install or activate a system.

The opt-in `modules/nixos/profiles/router/default.nix` profile provides a lightweight environment
for router hardware. Heimdall enables it with `dot.profiles.router.enable = true`: powersave CPU
governor, no automatic powertop tuning, one concurrent Nix build with two cores, empty NIX_PATH and
only the pinned nixpkgs registry entry. It defaults to minimal/headless operation with zram and
network diagnostic tools, with Plymouth, application hosting, persistence and YubiKey support off.

The network baseline uses networkd rather than NetworkManager, with nftables enabled and forwarded
traffic filtered. It removes inherited trusted interfaces and public/fallback DNS so each host's
networkd links own DNS. mDNS, forwarding, NAT, proxy and VPN are off by default; DHCP servers are
not enabled. Ordinary host settings can override the scalar defaults, including NetworkManager (the
profile uses priority 900 to beat the shared priority-1000 default). Empty global resolver and
interface-trust lists remain forced policies; link-specific DNS is still configurable.

Other hosts are unchanged unless they enable the profile. Disk layout, bootloader, Secure Boot,
interface matching, link settings, IP family selection, addresses, SSH, Tailscale and user
configuration remain host-owned. In particular, Heimdall's IPv4-only management link is not imposed
on other router hosts.

The host-scoped maintenance module retains fixes for the four-core CPU's kernel parameters and an
unsupported systemd service setting. The shared Disko helper's optional disk-swap setting is
retained because it describes the installed disk layout; other callers keep their existing defaults.

## Deployment and validation — 2026-11-24

The minimal configuration was built on Heimdall, activated with `test`, then switched permanently at
2026-11-23 23:30 UTC (2026-11-24 locally). Generation 7 is the system profile and default boot
entry:

`/nix/store/hs4cly5acsm4b07gzkk7nsf3rmk7d5xz-nixos-system-heimdall-26.11.20261111.d4f25a3`

The frozen deployment source is `/nix/store/vzbphbvjjn4p0fx39m021f2yl9z130vy-source`.

- Fresh, host-key-pinned ordinary SSH connections through `100.76.84.51:2222` passed after test,
  switch and removal of the temporary SSH socket override. Native sockets listen on 22 and 2222.
- Tailscale is running with the same node ID and IP. Tailscale SSH is enabled; DNS/routes are not
  accepted, no subnet advertisements or exit node are selected. Autoconnect and SOPS completed
  successfully; the secret is root-owned mode 0400.
- DNS remains on `192.168.8.1`; direct HTTPS to `cache.nixos.org` passed certificate validation.
  IPv4/IPv6 forwarding are zero. There are no failed systemd units.
- Old DHCP, proxy, panel and release services are inactive and absent from the new configuration.
  There is no UDP/67 listener or `arm-front` link. Runtime masks were retained for old gateway
  services. Gateway data on disk was not deleted.
- The test had an eight-minute automatic rollback timer, with old gateway services masked so a
  rollback would not restart them. The timer was cancelled after the successful permanent switch.
- Direct LAN SSH from eir remains unverified/unreachable, as before deployment: eir and Heimdall
  failed to resolve each other's LAN neighbor address. Eir's DHCP router is `192.168.8.1`. This LAN
  issue was not repaired, and no LAN reachability claim is made.

No reboot, reinstall or repartition was performed. Cold-boot behavior is not verified. Older boot
entries still contain the abandoned gateway; do not select them as a routine rollback without
accounting for their services. `deployable = false` remains intentional for automated target
selection. Never rerun Disko or an installer to apply ordinary configuration changes.

All removed Heimdall work remains in Git stash `1290daee42dd7e15b09b9e56cbbd23aa7bf4ffce` (including
its untracked-file parent). Do not pop the whole stash over these minimal files unless intentionally
restoring the gateway implementation.
