{ lib, pkgs, ... }:
let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
  aiSkills = import ./skills.nix { inherit lib pkgs; };

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

  skillSpecs = {
    "ai-commands" = {
      content = renderEntries "ai-commands" aiCommands.toCodexSkills;
    };
    "ai-agents" = {
      content = renderEntries "ai-agents" aiAgents.toClaudeMarkdown;
    };
  }
  // aiSkills.skills;

  mkSkillDir = content: pkgs.writeTextDir "SKILL.md" content;
  getSkillContent = spec: if builtins.isAttrs spec then spec.content else spec;
  getSkillPath =
    spec: if builtins.isAttrs spec && spec ? path then spec.path else mkSkillDir (getSkillContent spec);
  getSkillValue = getSkillContent;

  skillValues = lib.mapAttrs (_: getSkillValue) skillSpecs;
  skillPaths = lib.mapAttrs (_: getSkillPath) skillSpecs;
  skillEntries = lib.mapAttrsToList (name: path: {
    inherit name;
    inherit path;
  }) skillPaths;

  skillsDir = pkgs.linkFarm "shared-ai-skills" skillEntries;

  portableSkillValues = lib.mapAttrs (_: getSkillValue) aiSkills.skills;
  portableSkillPaths = lib.mapAttrs (_: getSkillPath) aiSkills.skills;
  portableSkillEntries = lib.mapAttrsToList (name: path: {
    inherit name path;
  }) portableSkillPaths;
  portableSkillsDir = pkgs.linkFarm "portable-ai-skills" portableSkillEntries;

  skills = skillValues;

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

    antigravityCli = {
      commands = aiCommands.toAntigravityCommands;
      agents = aiAgents.toAntigravityAgents;
      skills = portableSkillValues;
    };

    codex = {
      agents = aiAgents.toCodexAgents;
      commandSkillFiles = aiCommands.toCodexSkillFiles;
      context = base;
      contextOverride = base;
      customInstructions = base;
      inherit skillsDir;
      inherit skills;
    };

    opencode = {
      commands = aiCommands.toOpenCodeMarkdown;
      inherit (aiAgents) agents;
      renderAgents = aiAgents.toOpenCodeMarkdown;
      inherit skillsDir;
      skills = skillValues;
    };

    githubCopilotCli = {
      agents = aiAgents.toCopilotMarkdown;
      commandSkills = aiCommands.toCopilotSkills;
      commands = aiCommands.toClaudeMarkdown;
      context = base;
      skills = aiCommands.toCopilotSkills // portableSkillValues;
      inherit base;
    };

    piCodingAgent = {
      skills = portableSkillsDir;
    };

    hermesAgent = {
      skills = portableSkillPaths;
      documents = {
        "AGENTS.md" = base;
        "AI_AGENTS.md" = getSkillContent skillSpecs."ai-agents";
        "AI_COMMANDS.md" = getSkillContent skillSpecs."ai-commands";
      };
    };

    mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
  };
}
