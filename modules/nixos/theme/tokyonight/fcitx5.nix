{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && isLinux;
in
{
  config = mkIf enable {
    i18n.inputMethod.fcitx5 = {
      addons = with pkgs; [ fcitx5-tokyonight ];
      settings.addons =
        let
          shade = if cfg.style == "day" then "Day" else "Storm";
        in
        {
          classicui.globalSection = {
            Theme = "Tokyonight-${shade}";
            DarkTHeme = "Tokyonight-${shade}";
          };
        };
    };
  };
}
