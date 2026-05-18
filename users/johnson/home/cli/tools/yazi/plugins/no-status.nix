{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) no-status; };
    initLua = ''
      require("no-status"):setup()
    '';
  };
}
