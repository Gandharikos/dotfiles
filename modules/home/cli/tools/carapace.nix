{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;

  cfg = config.my.carapace;
in {
  options.my.carapace = {
    enable = mkEnableOption "carapace";
  };

  config = mkIf cfg.enable {
    programs.carapace = {
      # Carapace documentation
      # See: https://carapace-sh.github.io/carapace-bin/
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      # Prefer fzf-tab plugin
      enableZshIntegration = false;
      enableNushellIntegration = true;
    };
  };
}
