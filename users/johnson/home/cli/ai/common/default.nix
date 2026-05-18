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
      content = renderEntries "ai-commands" aiCommands.commands;
    };
    "ai-agents" = {
      content = renderEntries "ai-agents" aiAgents.agents;
    };
  }
  // aiSkills.skills;

  mkSkillDir = content: pkgs.writeTextDir "SKILL.md" content;
  getSkillContent = spec: if builtins.isAttrs spec then spec.content else spec;
  getSkillPath =
    spec: if builtins.isAttrs spec && spec ? path then spec.path else mkSkillDir (getSkillContent spec);

  skillEntries = lib.mapAttrsToList (name: spec: {
    inherit name;
    path = getSkillPath spec;
  }) skillSpecs;

  skillsDir = pkgs.linkFarm "shared-ai-skills" skillEntries;

  skills = lib.mapAttrs (_: getSkillContent) skillSpecs;

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
    };

    mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
  };
}
