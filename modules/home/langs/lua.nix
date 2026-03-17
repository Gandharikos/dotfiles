# modules/dev/lua.nix --- https://www.lua.org/
#
# I use lua for modding or Love2D for rapid gamedev prototyping (when godot is
# overkill and I have the luxury of avoiding JS). I write my Love games in
# fennel to get around some of lua's idiosynchrosies. That said, I install
# love2d on a per-project basis, so this module is rarely enabled.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.lua;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
in
{
  options.my.langs.lua = {
    enable = mkEnableOption "Lua development environment";
    xdg.enable = mkEnableOption "Lua XDG environment variables";
    love2D.enable = mkEnableOption "Love2D game development";
    fennel.enable = mkEnableOption "Fennel language";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        lua
        luajit
        (mkIf cfg.love2D.enable love2d)
        (mkIf cfg.fennel.enable fennel)
      ];
    })

    (mkIf cfg.xdg.enable {
      # The lua ecosystem has great XDG support out of the box, so...
    })
  ];
}
