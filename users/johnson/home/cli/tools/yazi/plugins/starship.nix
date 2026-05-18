{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) starship; };
    initLua = ''
      require("starship"):setup()
    '';
  };
}
