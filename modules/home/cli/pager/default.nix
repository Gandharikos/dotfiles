{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) str;
  inherit (lib.meta) getExe;
  less' = getExe pkgs.less;
  bat' = getExe pkgs.bat;
in {
  imports = lib.my.scanPaths ./.;
  options.my = {
    pager = mkOption {
      type = str;
      default = "${less'} -FR";
      description = "The pager to use";
    };
    manpager = mkOption {
      type = str;
      default = "sh -c 'col --no-backspaces --spaces | ${bat'} --plain --language=man'";
      description = "The manpages to use";
    };
  };

  config = {
    home.sessionVariables = {
      PAGER = config.my.pager;
      MANPAGER = config.my.manpager;
    };
  };
}
