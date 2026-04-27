{
  nix = {
    # NixOS schedules optimise jobs with systemd calendar strings.
    optimise.dates = [ "04:00" ];
  };
}
