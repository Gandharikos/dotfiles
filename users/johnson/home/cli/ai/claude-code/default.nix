{
  config,
  pkgs,
  lib,
  aiCommon,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) optionalAttrs;
  cfg = config.my.claude-code;
  hooks = lib.dot.importDir ./hooks {
    inherit
      config
      pkgs
      ;
  };
  mcpModuleEnabled = config.my.mcp.enable or false;
  sharedAiTools = aiCommon;
  claudeIcon = ./assets/claude.ico;
in
{
  imports = [
    ./permissions.nix
  ];

  options.my.claude-code = {
    enable = mkEnableOption "claude-code";
  };

  config = mkIf cfg.enable {
    # Install Claude icon for notifications
    xdg.dataFile."icons/claude.ico".source = claudeIcon;

    programs.claude-code = {
      enable = true;
      package = pkgs.llm-agents.claude-code;
      enableMcpIntegration = mkIf mcpModuleEnabled true;

      settings = {
        theme = "dark";
        inherit hooks;
        verbose = true;
        includeCoAuthoredBy = false;

        gitAttribution = false;
        statusLine = {
          type = "command";
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
        };
        attribution = {
          commit = "";
          pr = "";
        };

        env = {
          USE_BUILTIN_RIPGREP = "0";
        }
        // optionalAttrs mcpModuleEnabled {
          ENABLE_TOOL_SEARCH = "auto:5";
        };
      };

      inherit (sharedAiTools.claudeCode) agents commands;
      inherit (sharedAiTools) skills;
      context = sharedAiTools.base;
    };
  };
}
