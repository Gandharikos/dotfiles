{ lib, ... }:
let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };

  base = ./base.md;

  renderEntries =
    title: entries:
    ''
      ---
      name: ${title}
      description: Shared ${title} for this dotfiles repo.
      ---

    ''
    + (lib.concatStringsSep "\n\n" (
      lib.mapAttrsToList (entryName: content: ''
        ## ${entryName}
        ${content}
      '') entries
    ));

  aiAgentsDocument = renderEntries "ai-agents" aiAgents.toClaudeMarkdown;
  aiCommandsDocument = renderEntries "ai-commands" aiCommands.toCodexSkills;

  inherit (aiCommands) commands;
  inherit (aiAgents) agents;
in
{
  _module.args.aiCommon = {
    inherit
      agents
      base
      commands
      ;

    claudeCode = {
      commands = aiCommands.toClaudeMarkdown;
      agents = aiAgents.toClaudeMarkdown;
    };

    antigravityCli = {
      commands = aiCommands.toAntigravityCommands;
      agents = aiAgents.toAntigravityAgents;
    };

    codex = {
      agents = aiAgents.toCodexAgents;
      context = base;
      contextOverride = base;
      customInstructions = base;
    };

    opencode = {
      commands = aiCommands.toOpenCodeMarkdown;
      inherit (aiAgents) agents;
      renderAgents = aiAgents.toOpenCodeMarkdown;
    };

    githubCopilotCli = {
      agents = aiAgents.toCopilotMarkdown;
      commands = aiCommands.toClaudeMarkdown;
      context = base;
      inherit base;
    };

    hermesAgent = {
      documents = {
        "AGENTS.md" = base;
        "AI_AGENTS.md" = aiAgentsDocument;
        "AI_COMMANDS.md" = aiCommandsDocument;
      };
    };

    mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
  };
}
