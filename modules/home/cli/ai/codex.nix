{
  config,
  lib,
  pkgs,
  aiCommon,
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
      package = pkgs.llm-agents.codex;
      custom-instructions = aiCommon.codex.customInstructions;
      inherit (aiCommon.codex) skills;
    };
  };
}
