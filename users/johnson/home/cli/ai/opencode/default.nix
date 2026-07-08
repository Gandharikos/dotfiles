{
  config,
  pkgs,
  lib,
  aiCommon,
  ...
}:
let
  inherit (lib)
    getExe
    mkDefault
    mkEnableOption
    mkIf
    ;
  inherit (lib.meta) getExe';

  cat' = getExe' pkgs.coreutils "cat";

  sharedAiTools = aiCommon;
  cfg = config.my.opencode;
  mcpModuleEnabled = config.my.mcp.enable or false;

  defaultAgent = "dotfiles-expert";
  mainModel = "openrouter/openai/gpt-5.5";
  nanoModel = "openrouter/openai/gpt-5.4-nano";
  quickModel = "openrouter/openai/gpt-5.3-codex-spark";
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    sops.secrets.openrouter_api_key = { };

    home.shellAliases = {
      opencode-coding = "opencode --model ${quickModel}";
      opencode-deep = "opencode --model ${mainModel}";
      opencode-nano = "opencode --model ${nanoModel}";
      opencode-research = "opencode --agent ${defaultAgent}";
    };

    programs.opencode = {
      enable = true;
      package = pkgs.writeShellScriptBin "opencode" ''
        export OPENROUTER_API_KEY="$(${cat'} ${config.sops.secrets.openrouter_api_key.path})"
        exec ${getExe pkgs.llm-agents.opencode} "$@"
      '';
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
          "opencode-wakatime@latest"
        ];
      };

      inherit (sharedAiTools.opencode) commands;
      agents = sharedAiTools.opencode.renderAgents;
      skills = "${sharedAiTools.skillsDir}";
      context = "${sharedAiTools.base}";
    };
  };
}
