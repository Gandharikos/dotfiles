{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.glow;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.glow = {
    enable = mkEnableOption "glow";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ glow ];
    home.sessionVariables.GLAMOUR_STYLE = "light";

    xdg.configFile."glow/glow.yml".source =
      (inputs.nixago.lib.${pkgs.stdenv.hostPlatform.system}.make {
        data = {
          # show local files only; no network (TUI-mode only)
          local = true;
          # mouse support (TUI-mode only)
          mouse = true;
          # use pager to display markdown
          pager = true;
          # word-wrap at width
          width = 0;
        };
        output = "glow.yml";
        format = "yaml";
      }).configFile;
  };
}
