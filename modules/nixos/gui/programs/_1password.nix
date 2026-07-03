{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.dot) gui;
  name = config.dot.primaryUser;
  cfg = config.dot.gui._1password;
in
{
  options.dot.gui._1password = {
    enable = mkEnableOption "1Password" // {
      default = gui.enable;
    };
  };

  config = mkIf (gui.enable && cfg.enable) {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ name ];
      };
    };
  };
}
