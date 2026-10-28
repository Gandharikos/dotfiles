{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkForce mkIf;
  cfg = config.nixporn;
  inherit (cfg) palette;
  inherit (cfg.colorschemes.solarized-osaka) slug;
  source = pkgs.nixporn.solarized-osaka;
  hasNixcord = options ? programs && options.programs ? nixcord;
  enable =
    cfg.enable
    && cfg.colorscheme == "solarized-osaka"
    && cfg.nixcord.enable
    && (config.programs.nixcord.enable or false);
  themeName = "${slug}.css";
  # Upstream craftzdog/solarized-osaka.nvim leaves several Tokyonight template
  # placeholders unexpanded in extras/discord/*.css.
  rawCss =
    builtins.replaceStrings
      [
        "\${bg_dark1}"
        "\${blue0}"
        "\${blue1}"
        "\${blue7}"
        "\${dark5}"
        "\${pink}"
      ]
      [
        palette.bg
        palette.blue700
        palette.blue300
        palette.blue900
        palette.base01
        palette.magenta
      ]
      (lib.fileContents "${source}/extras/discord/${slug}.css");
  transparentCss = lib.optionalString cfg.transparent ''

    :root,
    .theme-light,
    .theme-dark {
      --background: transparent !important;
      --background-primary: transparent !important;
      --bg-base-primary: transparent !important;
      --background-mobile-primary: transparent !important;
      --home-background: transparent !important;
      --chat-background: transparent !important;
      --chat-input-container-background: transparent !important;
    }

    body,
    #app-mount {
      background: transparent !important;
    }
  '';
in
{
  config = lib.optionalAttrs hasNixcord (
    mkIf enable {
      home.file."${config.programs.nixcord.configDir}/themes/${themeName}".text = mkForce (
        rawCss + transparentCss
      );
    }
  );
}
