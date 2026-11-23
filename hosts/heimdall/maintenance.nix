{ lib, ... }:
{
  # Filter the merged value rather than replacing the inherited security/boot parameters.
  # This option extension is imported only by Heimdall; other hosts retain their declarations.
  options.boot.kernelParams = lib.mkOption {
    apply = builtins.filter (
      param:
      !(builtins.elem param [
        "nohz_full=4-7"
        "i915.fastboot=1"
      ])
    );
  };

  # Null renders an empty assignment and still warns; omit the unknown field entirely.
  # Keep every other inherited service setting and do not invent a different OOM policy.
  options.systemd.services = lib.mkOption {
    apply =
      services:
      services
      // {
        nix-daemon = services.nix-daemon // {
          serviceConfig = builtins.removeAttrs services.nix-daemon.serviceConfig [ "OOMDScoreAdjust" ];
        };
      };
  };
}
