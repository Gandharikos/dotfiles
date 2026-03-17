{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
  inherit (config.my.theme.colorscheme) palette slug;
in
{
  config = mkIf cfg.enable {
    home = {
      # TODO: use gowall to change wallpaper to apply my colorscheme
      packages = with pkgs; [
        gowall
      ];
      file.".config/gowall/config.yml".text = with palette; ''
        themes:
          - name: "${slug}"
            colors:
              - "#${black}"
              - "#${bright_black}"
              - "#${yellow}"
              - "#${green}"
              - "#${bright_yellow}"
              - "#${white}"
              - "#${bright_white}"
              - "#${cyan}"
              - "#${bright_cyan}"
              - "#${blue}"
              - "#${bright_red}"
              - "#${bright_blue}"
              - "#${red}"
              - "#${bright_green}"
              - "#${magenta}"
              - "#${bright_magenta}"
      '';
    };
  };
}
