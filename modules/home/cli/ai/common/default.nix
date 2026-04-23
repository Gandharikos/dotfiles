{ lib, pkgs, ... }:
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

  renderedSkills = {
    "ai-commands" = renderEntries "ai-commands" aiCommands.commands;
    "ai-agents" = renderEntries "ai-agents" aiAgents.agents;
  };

  mkSkillDir = content: pkgs.writeTextDir "SKILL.md" content;

  skillEntries = lib.mapAttrsToList (name: content: {
    inherit name;
    path = mkSkillDir content;
  }) renderedSkills;

  skillsDir = pkgs.linkFarm "shared-ai-skills" skillEntries;

  skills = renderedSkills;

  inherit (aiCommands) commands;
  inherit (aiAgents) agents;
in
{
  _module.args.aiCommon = {
    inherit
      agents
      base
      commands
      skills
      skillsDir
      ;

    claudeCode = {
      commands = aiCommands.toClaudeMarkdown;
      agents = aiAgents.toClaudeMarkdown;
      inherit skillsDir;
    };

    geminiCli = {
      commands = aiCommands.toGeminiCommands;
      agents = aiAgents.toGeminiAgents;
      inherit skills;
    };

    codex = {
      context = base;
      customInstructions = base;
      inherit skillsDir;
      inherit skills;
    };

    opencode = {
      commands = aiCommands.toOpenCodeMarkdown;
      agents = aiAgents.toOpenCodeMarkdown;
      renderAgents = aiAgents.toOpenCodeMarkdown;
    };

    mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
  };
}
