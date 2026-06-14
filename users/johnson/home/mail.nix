{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.meta) getExe';
  cfg = config.my.mail;
in
{
  options.my.mail.enable = mkEnableOption "mail" // {
    default = true;
  };

  config = mkIf cfg.enable {
    my.aerc.enable = true;

    accounts.email.maildirBasePath = ".mail";

    accounts.email.accounts.gmail = {
      primary = true;
      flavor = "gmail.com";
      address = config.my.email;
      userName = config.my.email;
      realName = config.my.fullName;
      passwordCommand = [
        (getExe' pkgs.coreutils "cat")
        config.sops.secrets.gmail_app_password.path
      ];
      aerc.enable = true;
    };

    sops.secrets.gmail_app_password = { };
  };
}
