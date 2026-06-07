{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my._1password-cli;
in
{
  options.my._1password-cli = {
    enable = mkEnableOption "1password-cli";
    enableSshSocket = mkEnableOption "ssh-agent socket";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age-plugin-1p
      _1password-cli
    ];

    programs = {
      ssh.settings."*" = mkIf cfg.enableSshSocket {
        AddKeysToAgent = "yes";
        IdentityAgent = "${config.home.homeDirectory}/.1password/agent.sock";
      };
    };
  };
}
