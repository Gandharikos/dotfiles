{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.wakatime;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.wakatime = {
    enable = mkEnableOption "wakatime";
  };

  config = mkIf cfg.enable {
    sops.secrets.wakatime = {
      sopsFile = "${self}/secrets/${config.my.name}/wakatime";
      path = "${config.home.homeDirectory}/.wakatime.cfg";
      mode = "0600";
      format = "binary";
    };

    home.packages = [
      pkgs.wakatime-cli
    ];
  };
}
