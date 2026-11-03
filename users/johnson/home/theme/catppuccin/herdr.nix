{ config, lib, ... }:
{
  config = lib.mkIf (config.nixporn.colorscheme == "catppuccin" && config.my.herdr.enable) {
    programs.herdr.settings.theme.name = lib.mkDefault (
      if config.nixporn.colorschemes.catppuccin.flavor == "latte" then
        "catppuccin-latte"
      else
        "catppuccin"
    );
  };
}
