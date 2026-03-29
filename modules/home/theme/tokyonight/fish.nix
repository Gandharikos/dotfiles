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
  fishCfg = config.my.fish;
  enable = cfg.enable && fishCfg.enable;
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf enable {
    # Install modern fish theme format (fish 3.4.0+)
    xdg.configFile."fish/themes/${slug}.theme".source = "${src}/extras/fish_themes/${slug}.theme";

    programs.fish.interactiveShellInit = ''
      fish_config theme choose ${slug}
    '';
  };
}
