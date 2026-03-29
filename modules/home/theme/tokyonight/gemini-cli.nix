{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) removeAttrs;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && config.my.gemini-cli.enable;
  inherit (config.my.theme.colorscheme) slug;

  # Use builtins.fromJSON to avoid home-manager metadata
  rawTheme = builtins.fromJSON (builtins.readFile "${src}/extras/gemini_cli/${slug}.json");

  # Remove unsupported fields from text section
  cleanedTheme = rawTheme // {
    text = removeAttrs (rawTheme.text or { }) [ "response" ];
  };
in
{
  config = mkIf enable {
    programs."gemini-cli".settings.ui = {
      theme = slug;
      customThemes."${slug}" = cleanedTheme // {
        type = "custom";
        name = slug;
      };
    };
  };
}
