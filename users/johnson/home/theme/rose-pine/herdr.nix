{ config, lib, ... }:
{
  config = lib.mkIf (config.nixporn.colorscheme == "rose-pine" && config.my.herdr.enable) {
    programs.herdr.settings.theme.name = lib.mkDefault "rose-pine";
  };
}
