{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.my.theme.tokyonight;
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf cfg.enable {
    programs.yazi = {
      # plugins = {
      #   yatline = pkgs.yaziPlugins.yatline;
      # };
      # initLua = ''
      #   local tokyo_night_theme = require("yatline-tokyo-night"):setup("${cfg.style}") -- or moon/storm/day
      #   require("yatline"):setup({
      #     theme = tokyo_night_theme
      #   })
      # '';
      theme = {
        "$scheme" = "https://yazi-rs.github.io/schemas/theme.json";
        flavor.use = slug;
      };
    };
    xdg.configFile."yazi/flavors/${slug}.yazi/flavor.toml" = mkIf config.programs.yazi.enable {
      source = "${src}/extras/yazi/${slug}.toml";
    };
  };
}
