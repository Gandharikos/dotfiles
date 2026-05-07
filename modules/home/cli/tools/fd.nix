{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.fd;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.dot.fd = {
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
