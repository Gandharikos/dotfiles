{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.dot.glow;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkDefault;

  yamlFormat = pkgs.formats.yaml { };
  glowConfig = {
    # show local files only; no network (TUI-mode only)
    local = true;
    # mouse support (TUI-mode only)
    mouse = true;
    # use pager to display markdown
    pager = true;
    # word-wrap at width
    width = 0;
  };
in
{
  options.dot.glow = {
    enable = mkEnableOption "glow";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ glow ];
    home.sessionVariables.GLAMOUR_STYLE = mkDefault "light";

    xdg.configFile."glow/glow.yml".source = yamlFormat.generate "glow.yml" glowConfig;
  };
}
