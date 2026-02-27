{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.my) name;
  cfg = config.my.desktop._1password;
  isPersist = config.my.persistence.enable;
in {
  options.my.desktop._1password = {
    enable =
      mkEnableOption "1Password"
      // {
        default = config.my.desktop.enable;
      };
  };

  config = mkIf cfg.enable {
    programs = {
      _1password .enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [name];
      };
    };

    environment.persistence."/persist" = mkIf isPersist {
      users.${name} = {
        directories = [
          ".config/1Password"
        ];
      };
    };
  };
}
