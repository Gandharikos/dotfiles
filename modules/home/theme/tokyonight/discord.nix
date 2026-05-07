{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.dot.theme.tokyonight;
  enable = cfg.enable && config.dot.gui.apps.discord.enable;
  inherit (config.dot.theme.general) transparent;
  inherit (config.dot.theme.colorscheme) slug;
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
