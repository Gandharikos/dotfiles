{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.spicetify =
      let
        tokyonightTheme = pkgs.fetchFromGitHub {
          owner = "evening-hs";
          repo = "Spotify-Tokyo-Night-Theme";
          rev = "d88ca06eaeeb424d19e0d6f7f8e614e4bce962be";
          hash = "sha256-cLj9v8qtHsdV9FfzV2Qf4pWO8AOBXu51U/lUMvdEXAk=";
        };
      in
      {
        theme = {
          name = "Tokyo";
          src = tokyonightTheme;
          overwriteAssets = true;
        };
        colorScheme =
          if cfg.style == "night" then
            "Night"
          else if cfg.style == "storm" then
            "Storm"
          else if cfg.style == "day" then
            "Light"
          else
            "Night";
      };
  };
}
