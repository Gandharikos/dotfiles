{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  options.dot.profiles.router.enable =
    lib.mkEnableOption "a lightweight base environment for router hardware, without enabling routing";

  config = lib.mkIf config.dot.profiles.router.enable {
    dot = {
      profiles = {
        minimal.enable = lib.mkDefault true;
        headless.enable = lib.mkDefault true;
      };
      selfhosted.enable = lib.mkDefault false;
      boot.plymouth.enable = lib.mkDefault false;
      persistence.enable = lib.mkDefault false;
      yubikey.enable = lib.mkDefault false;
      services.zram.enable = lib.mkDefault true;
      networking = {
        proxy.enable = lib.mkDefault false;
        vpn.enable = lib.mkDefault false;
      };
    };
    networking = {
      # Beat the shared mkDefault true, but allow an ordinary host override.
      networkmanager.enable = lib.mkOverride 900 false;
      useNetworkd = lib.mkDefault true;
      # DNS belongs to the host's networkd links, not the shared public preset.
      nameservers = lib.mkForce [ ];
      nat.enable = lib.mkDefault false;
      nftables.enable = lib.mkDefault true;
      firewall = {
        enable = lib.mkDefault true;
        filterForward = lib.mkDefault true;
        # Preserve local DNS/proxy access without trusting VPN, LAN or container interfaces.
        trustedInterfaces = lib.mkForce [ "lo" ];
      };
    };
    systemd.network.enable = lib.mkDefault true;
    services.resolved.settings.Resolve = {
      FallbackDNS = lib.mkForce [ ];
      MulticastDNS = lib.mkDefault false;
    };
    # Forwarding is enabled only by an explicit host/gateway configuration.
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkDefault 0;
      "net.ipv6.conf.all.forwarding" = lib.mkDefault 0;
    };
    environment.systemPackages = with pkgs; [
      ethtool
      pciutils
      usbutils
      tcpdump
      iproute2
      bind
    ];
    powerManagement = {
      enable = lib.mkDefault true;
      cpuFreqGovernor = lib.mkDefault "powersave";
      # Avoid automatic NIC/USB tuning on remotely managed appliances.
      powertop.enable = lib.mkDefault false;
    };
    nix = {
      # Override the shared all-input registry and automatic build parallelism.
      nixPath = lib.mkForce [ ];
      registry = lib.mkForce { nixpkgs.flake = inputs.nixpkgs; };
      settings = {
        max-jobs = lib.mkForce 1;
        cores = lib.mkForce 2;
      };
    };
  };
}
