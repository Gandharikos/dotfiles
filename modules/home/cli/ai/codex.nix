{
  config,
  lib,
  ...
}: let
  cfg = config.my.codex;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in {
  options.my.codex = {
    enable = mkEnableOption "codex";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
    };

    home.persistence."/persist".directories = [
      ".codex"
    ];
  };
}
