{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.my) relativeToConfig;
  cfg = config.my.services.karabiner;
  kbCfg = config.my.keyboard;
in
{
  options.my.services.karabiner = {
    enable = mkOption {
      type = lib.types.bool;
      default = kbCfg.backend == "karabiner";
      internal = true;
      readOnly = true;
      description = "Whether to enable Karabiner keyboard remapping";
    };

    configFile = mkOption {
      type = lib.types.path;
      default = relativeToConfig "karabiner/karabiner.json";
      description = "Path to the primary Karabiner configuration file.";
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "karabiner-elements" ];
    hm.xdg.configFile."karabiner/karabiner.json".source = cfg.configFile;
  };
}
