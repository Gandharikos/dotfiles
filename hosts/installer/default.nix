{ inputs, ... }:
{
  pure = true;
  modules = [ ./config.nix ];
  specialArgs = { inherit inputs; };
}
