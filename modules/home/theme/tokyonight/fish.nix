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
  fishCfg = config.dot.fish;
  enable = cfg.enable && fishCfg.enable;
  inherit (config.dot.theme.colorscheme) slug;
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
