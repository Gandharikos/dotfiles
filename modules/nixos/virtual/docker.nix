{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.virtual.docker;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.virtual.docker = {
    enable = mkEnableOption "Docker" // {
      default = config.dot.virtual.enable;
    };
  };
  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      daemon.settings = {
        # enables pulling using containerd, which supports restarting from a partial pull
        # https://docs.docker.com/storage/containerd/
        "features" = {
          "containerd-snapshotter" = true;
        };
      };

      # start dockerd on boot.
      # This is required for containers which are created with the `--restart=always` flag to work.
      enableOnBoot = true;

      # auto prune unused containers and images
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
      };
    };
  };
}
