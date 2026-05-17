{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  src = pkgs.vimPlugins.tokyonight-nvim;
  enable = config.nixporn.colorscheme == "tokyonight" && config.my.gui.apps.discord.enable;
  transparent = config.nixporn.transparent;
  inherit (config.nixporn.colorschemes.tokyonight) slug;
  discordTheme = builtins.replaceStrings [ "\${pink}" ] [ "var(--guild-boosting-pink)" ] (
    builtins.readFile "${src}/extras/discord/${slug}.css"
  );
in
{
  config = mkIf enable {
    programs.nixcord.config = {
      inherit transparent;
      frameless = true;
      enabledThemes = [
        "${slug}.css"
      ];
    };

    home.file."${config.programs.nixcord.configDir}/themes/${slug}.css".text = discordTheme;
  };
}
