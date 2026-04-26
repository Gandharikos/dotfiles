{
  nix = {
    # NixOS uses systemd timer format for gc and optimise intervals
    gc.interval = "weekly";
    optimise.interval = [ { Hour = 4; } ];
  };
}
