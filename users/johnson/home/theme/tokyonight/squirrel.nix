{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf;
in
{
  config = mkIf (config.nixporn.colorscheme == "tokyonight") {
    nixporn.squirrel = {
      enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
      dir = mkDefault config.my.gui.rime.dir;
    };
  };
}
