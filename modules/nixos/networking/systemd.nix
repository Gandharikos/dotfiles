{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;
  inherit (lib.attrsets) genAttrs;
  inherit (config.dot.device) ethernetDevices;
in
{
  # run `ip a` to find out
  options.dot.device.ethernetDevices = mkOption {
    type = listOf str;
    default = [ ];
    description = "The network devices of the system";
  };

  config = {
    # systemd DNS resolver daemon
    services.resolved = {
      enable = true;

      # Avoid unauthenticated link-local name resolution; mDNS is configured separately.
      settings.Resolve.LLMNR = false;
    };

    systemd = {
      # allow for the system to boot without waiting for the network interfaces are online
      network = {
        wait-online.enable = false;
        networks = genAttrs ethernetDevices (device: {
          matchConfig.Name = device;
          networkConfig.DHCP = "yes";
        });
      };

      services = {
        # https://github.com/systemd/systemd/blob/e1b45a756f71deac8c1aa9a008bd0dab47f64777/NEWS#L13
        NetworkManager-wait-online.enable = false;

        # Prefer restart under the new configuration over stop-old/start-new.
        # This does not prevent restarts during activation.
        systemd-networkd.stopIfChanged = false;
        systemd-resolved.stopIfChanged = false;
      };
    };
  };
}
