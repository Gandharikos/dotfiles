{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.television.settings.theme = "tokyonight";
  };
}
