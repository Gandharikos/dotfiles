{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;

  cfg = config.my.topgrade;
in
{
  options.my.topgrade = {
    enable = mkEnableOption "topgrade";
  };

  config = mkIf cfg.enable {
    programs.topgrade = {
      enable = true;

      settings = {
        misc = {
          no_retry = true;
          display_time = true;
          skip_notify = true;
        };
        git = {
          repos = [
            "~/Repos/*"
            "~Projects/*"
            "~/dotfiles/"
          ];
        };
      };
    };
  };
}
