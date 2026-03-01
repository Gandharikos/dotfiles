{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.my) isx86Linux;
  cfg = config.my.machine;
in {
  # imports = [
  # ./low-latency.nix
  # ./settings.nix
  # ];

  options.my.machine.hasSound = mkEnableOption "Whether the system has sound";

  config = mkIf cfg.hasSound {
    environment.systemPackages = with pkgs; [
      pulseaudio # provides `pactl`, which is required by some apps(e.g. sonic-pi)
    ];

    # PipeWire is a new low-level multimedia framework.
    # It aims to offer capture and playback for both audio and video with minimal latency.
    # It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications.
    # PipeWire has a great bluetooth support, it can be a good alternative to PulseAudio.
    #     https://nixos.wiki/wiki/PipeWire
    services.pipewire = {
      enable = true;

      audio.enable = true;
      pulse.enable = true;
      jack.enable = true;
      # package = pkgs-unstable.pipewire;
      alsa = {
        enable = true;
        support32Bit = isx86Linux pkgs;
      };
    };

    systemd.user.services = {
      pipewire.wantedBy = ["default.target"];
      pipewire-pulse.wantedBy = ["default.target"];
    };
  };
}
