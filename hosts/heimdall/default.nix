{
  class = "nixos";
  arch = "x86_64";
  # Hardware must be reviewed before this host becomes an installation target.
  deployable = false;
  modules = [ ./config.nix ];
}
