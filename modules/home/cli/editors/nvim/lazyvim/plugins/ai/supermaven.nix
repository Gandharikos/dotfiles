{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.home) homeDirectory;
  inherit (config.my) name;
  cfg = config.my.neovim.lazyvim.supermaven;
in
{
  options.my.neovim.lazyvim.supermaven = {
    enable = mkEnableOption "AI plugin - Supermaven";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        supermaven-nvim
      ];

      imports = [ "lazyvim.plugins.extras.ai.supermaven" ];
    };

    sops.secrets.supermaven = {
      sopsFile = "${self}/secrets/${name}/supermaven";
      path = "${homeDirectory}/.supermaven/config.json";
      mode = "0400";
      format = "binary";
    };
  };
}
