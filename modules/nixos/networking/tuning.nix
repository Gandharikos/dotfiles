{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.networking.tuning;
  inherit (lib) mkOption types;
in
{
  options.dot.networking.tuning = {
    congestionControl = mkOption {
      type = types.nullOr (
        types.enum [
          "reno"
          "cubic"
          "bbr"
        ]
      );
      default = null;
      description = "Optional host TCP congestion control. Null leaves the existing kernel/NixOS setting unchanged.";
    };
    defaultQdisc = mkOption {
      type = types.nullOr (
        types.enum [
          "fq"
          "fq_codel"
          "cake"
        ]
      );
      default = null;
      description = "Optional host default queue discipline, independent of congestion control. Does not reconfigure existing interface qdiscs or supply CAKE bandwidth shaping.";
    };
    mtuProbing = mkOption {
      type = types.nullOr (
        types.enum [
          0
          1
          2
        ]
      );
      default = null;
      description = "Optional TCP MTU probing: 0 disables, 1 probes on black-hole detection, 2 always probes. Null preserves the existing setting.";
    };
  };

  config.boot = {
    kernelModules =
      lib.optional (cfg.congestionControl == "bbr") "tcp_bbr"
      ++ lib.optional (cfg.defaultQdisc != null) "sch_${cfg.defaultQdisc}";
    kernel.sysctl =
      lib.optionalAttrs (cfg.congestionControl != null) {
        "net.ipv4.tcp_congestion_control" = cfg.congestionControl;
      }
      // lib.optionalAttrs (cfg.defaultQdisc != null) {
        "net.core.default_qdisc" = cfg.defaultQdisc;
      }
      // lib.optionalAttrs (cfg.mtuProbing != null) {
        "net.ipv4.tcp_mtu_probing" = cfg.mtuProbing;
      };
  };
}
