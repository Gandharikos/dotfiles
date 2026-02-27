{
  lib,
  config,
  ...
}: let
  cfg = config.my.pet;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in {
  options.my.pet.enable = mkEnableOption "Pet tool";

  config = mkIf cfg.enable {
    programs.pet = {
      enable = true;
      settings = {
        General = {
          editor = "nvim";
          selectcmd = "fzf --ansi";
          sortby = "command";
          color = true;
          format = "$command | $description | $tags |";
        };
      };
      snippets = [
        {
          command = "sudo lsof -nP -iTCP -sTCP:LISTEN";
          description = "Show services which listen to any TCP port";
          tag = ["cmd" "networking" "system"];
        }
        {
          command = "journalctl -b -p err --no-pager";
          description = "Show boot errors from the current boot";
          tag = ["cmd" "system" "logs"];
        }
      ];
    };
  };
}
