{ config, lib, ... }:
{
  config = lib.mkIf (config.nixporn.colorscheme == "solarized-osaka" && config.my.herdr.enable) {
    programs.herdr.settings.theme = {
      name = lib.mkDefault "solarized";
      custom = with config.nixporn.palette; {
        panel_bg = bg;
        text = fg;
        accent = cyan;
      };
    };
  };
}
