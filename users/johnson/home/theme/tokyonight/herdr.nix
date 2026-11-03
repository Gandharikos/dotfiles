{ config, lib, ... }:
{
  config = lib.mkIf (config.nixporn.colorscheme == "tokyonight" && config.my.herdr.enable) {
    programs.herdr.settings.theme.name = lib.mkDefault "tokyo-night";
  };
}
