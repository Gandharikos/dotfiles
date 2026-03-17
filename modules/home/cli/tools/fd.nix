{
  config,
  lib,
  ...
}:
let
  cfg = config.my.fd;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.fd = {
    enable = mkEnableOption "fd";
  };

  config = mkIf cfg.enable {
    programs.fd = {
      enable = true;
      ignores = [
        ".git/"
        ".direnv/"
      ];
      hidden = true;
    };
  };
}
