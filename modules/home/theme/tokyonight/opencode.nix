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
  enable = cfg.enable && config.dot.opencode.enable;
  inherit (config.dot.theme.colorscheme) slug;
in
{
  config = mkIf enable {
    # OpenCode v1.2.15+ requires TUI settings in separate tui section
    programs.opencode.tui.theme = slug;

    xdg.configFile."opencode/themes/${slug}.json".source = "${src}/extras/opencode/${slug}.json";
  };
}
