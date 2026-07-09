{
  lib,
  pkgs,
  ...
}:
{
  skills = import ./skills { inherit lib pkgs; };
}
