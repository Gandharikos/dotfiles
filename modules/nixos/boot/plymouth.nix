{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str package;

  cfg = config.my.boot.plymouth;
  plymouth' = getExe' pkgs.plymouth "plymouth";
in
{
  options.my.boot.plymouth = {
    enable = mkEnableOption "plymouth boot splash" // {
      default = true;
    };

    playFullAnimation = mkEnableOption "Wait for the boot animation to finish playing before opening login shell.";
    themesPackage = mkOption {
      default = pkgs.my.plymouth-themes.override { inherit (cfg) themeName; };
      type = package;
    };
    themeName = mkOption {
      type = str;
      default = "angular_alt";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      plymouth = {
        enable = true;
        themePackages = [ cfg.themesPackage ];
        theme = cfg.themeName;
      };

      consoleLogLevel = 0;
      initrd.verbose = false;
      kernelParams = [
        "boot.shell_on_fail"
      ];
    };

    # make plymouth work with sleep
    powerManagement = {
      powerDownCommands = "${plymouth'} --show-splash";
      resumeCommands = "${plymouth'} --quit";
    };

    systemd.services.plymouth-quit.serviceConfig.ExecStartPre =
      mkIf cfg.playFullAnimation "${getExe' pkgs.coreutils-full "sleep"} 5";
  };
}
