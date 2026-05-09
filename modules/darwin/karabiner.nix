{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.dot) relativeToConfig;
  cfg = config.dot.services.karabiner;
  kbCfg = config.dot.keyboard;
in
{
  options.dot.services.karabiner = {
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
    dot.users.${config.dot.primaryUser}.home.xdg.configFile."karabiner/karabiner.json".source =
      cfg.configFile;
  };
}
