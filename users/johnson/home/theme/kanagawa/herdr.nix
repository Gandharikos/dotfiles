{ config, lib, ... }:
{
  config = lib.mkIf (config.nixporn.colorscheme == "kanagawa" && config.my.herdr.enable) {
    programs.herdr.settings.theme.name = lib.mkDefault "kanagawa";
  };
}
