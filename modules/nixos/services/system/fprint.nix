{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.services.fprint;
in {
  options.my.services.fprint = {
    enable =
      mkEnableOption "Enable fingerprint login"
      // {
        default = config.my.security.enable;
      };
  };

  config = mkIf cfg.enable {
    # fingerprint login
    # doesn't work because thanks drivers
    services.fprintd = {
      enable = true;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-goodix;
      };
    };
  };
}
