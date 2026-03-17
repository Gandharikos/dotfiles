{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.conda;
in
{
  options.my.conda = {
    enable = mkEnableOption "conda" // {
      default = isLinux;
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.conda ];

      file.".condarc" = {
        text = ''
          channels:
            - conda-forge
            - defaults
          env_prompt: \'\'
          auto_activate_base: false
        '';
        executable = false;
      };
    };
  };
}
