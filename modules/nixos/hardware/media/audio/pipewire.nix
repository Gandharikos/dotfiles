{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.my) isx86Linux;
  lowLatencyQuantum = 32;
  lowLatencyRate = 48000;
  lowLatencyPeriod = "${toString lowLatencyQuantum}/${toString lowLatencyRate}";
in
{
  config = mkIf config.my.gui.enable {
    environment.systemPackages = with pkgs; [
      easyeffects
      pwvucontrol
    ];

    # pipewire is newer and just better
    services.pipewire = {
      enable = true;

      audio.enable = true;
      pulse.enable = true;
      jack.enable = true;

      alsa = {
        enable = true;
        support32Bit = isx86Linux pkgs;
      };

      extraConfig.pipewire = {
        "10-loopback" = {
          "context.modules" = [
            {
              "node.description" = "playback loop";
              "audio.position" = [
                "FL"
                "FR"
              ];

              "capture.props" = {
                "node.name" = "playback_sink";
                "node.description" = "playback-sink";
                "media.class" = "Audio/Sink";
              };

              "playback.props" = {
                "node.name" = "playback_sink.output";
                "node.description" = "playback-sink-output";
                "media.class" = "Audio/Source";
                "node.passive" = true;
              };
            }
          ];
        };

        "92-low-latency"."context.properties" = {
          "default.clock.rate" = lowLatencyRate;
          "default.clock.quantum" = lowLatencyQuantum;
          "default.clock.min-quantum" = lowLatencyQuantum;
          "default.clock.max-quantum" = lowLatencyQuantum;
        };
      };

      extraConfig.pipewire-pulse."92-low-latency"."pulse.properties" = {
        "pulse.min.req" = lowLatencyPeriod;
        "pulse.default.req" = lowLatencyPeriod;
        "pulse.max.req" = lowLatencyPeriod;
        "pulse.min.quantum" = lowLatencyPeriod;
        "pulse.max.quantum" = lowLatencyPeriod;
      };

      extraConfig.client."92-low-latency"."stream.properties" = {
        "node.latency" = lowLatencyPeriod;
        "resample.quality" = 1;
      };
    };

    systemd.user.services = {
      pipewire.wantedBy = [ "default.target" ];
      pipewire-pulse.wantedBy = [ "default.target" ];
    };
  };
}
