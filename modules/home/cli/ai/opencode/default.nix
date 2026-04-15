{
  config,
  pkgs,
  lib,
  aiCommon,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  sharedAiTools = aiCommon;

  cfg = config.my.opencode;
in
{
  imports = lib.my.scanPaths ./.;

  options.my.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      package = pkgs.llm-agents.opencode;

      tui.theme = lib.mkDefault "opencode";

      settings = {
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;
      };

      inherit (sharedAiTools.claudeCode) agents;
      inherit (sharedAiTools.claudeCode) commands;

      rules = builtins.readFile (lib.my.getFile "modules/home/cli/ai/common/base.md");
    };
  };
}
