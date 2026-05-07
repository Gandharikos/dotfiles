{
  config,
  pkgs,
  lib,
  aiCommon,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;
  sharedAiTools = aiCommon;
  cfg = config.dot.opencode;
  mcpModuleEnabled = config.dot.mcp.enable or false;

  defaultAgent = "dotfiles-expert";
  mainModel = "openai/gpt-5.4";
  nanoModel = "openai/gpt-5.4-nano";
  quickModel = "openai/gpt-5.3-codex-spark";
in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      opencode-coding = "opencode --model ${quickModel}";
      opencode-deep = "opencode --model ${mainModel}";
      opencode-nano = "opencode --model ${nanoModel}";
      opencode-research = "opencode --agent ${defaultAgent}";
    };

    programs.opencode = {
      enable = true;
      package = pkgs.llm-agents.opencode;
      enableMcpIntegration = mkIf mcpModuleEnabled true;

      tui.theme = mkDefault "opencode";

      settings = {
        model = mainModel;
        share = "manual";
        autoupdate = false;
        small_model = quickModel;
        default_agent = defaultAgent;
        compaction = {
          auto = true;
          prune = true;
          reserved = 20000;
        };
        command = {
          quick = {
            template = "Make fast, minimal edits and keep responses concise.";
            model = quickModel;
            agent = defaultAgent;
            subtask = true;
          };
          research = {
            template = "Do deliberate analysis before edits, include caveats and verification steps.";
            model = mainModel;
            agent = defaultAgent;
          };
          nano = {
            template = "Keep each action minimal and targeted for small-surface modifications.";
            model = nanoModel;
            agent = defaultAgent;
            subtask = true;
          };
        };
        plugin = [
          "opencode-gemini-auth@latest"
          "opencode-pty@latest"
          "oh-my-openagent@latest"
        ];
      };

      inherit (sharedAiTools.opencode) agents commands;
      skills = "${sharedAiTools.skillsDir}";
      context = "${sharedAiTools.base}";
    };
  };
}
