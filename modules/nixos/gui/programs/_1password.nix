{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.my) name;
  cfg = config.my.gui._1password;
in
{
  options.my.gui._1password = {
    enable = mkEnableOption "1Password" // {
      default = config.my.gui.enable;
    };
  };

  config = mkIf cfg.enable {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ name ];
      };
    };
  };
}
