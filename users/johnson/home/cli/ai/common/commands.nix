{ lib, ... }:
let
  rawCommands = import ./commands { inherit lib; };

  modelValue =
    provider: model:
    if model == null then
      null
    else if builtins.isAttrs model then
      model.${provider} or null
    else
      model;

  parseFrontmatter =
    text:
    let
      parts = lib.splitString "---" text;
      hasFrontmatter = lib.length parts >= 3;
      frontmatter = if hasFrontmatter then lib.elemAt parts 1 else "";
      content = if hasFrontmatter then lib.concatStringsSep "---" (lib.drop 2 parts) else text;
      lines = lib.filter (line: line != "") (map lib.trim (lib.splitString "\n" frontmatter));
      parseLine =
        line:
        let
          pair = lib.splitString ":" line;
          key = lib.head pair;
          value = lib.trim (lib.concatStringsSep ":" (lib.tail pair));
        in
        {
          name = key;
          inherit value;
        };
    in
    {
      attrs = builtins.listToAttrs (map parseLine lines);
      content = lib.trim content;
    };

  agentModelDefaults = {
    explore = {
      claude = "haiku";
      copilot = "claude-haiku-4.5";
      antigravity = "gemini-3.1-flash-lite-preview";
      opencode = "openai/gpt-5.4-mini";
    };
  };

  commandAgents = {
    changelog = "refactorer";
    commit-changes = "refactorer";
    deep-check = "test-runner";
    dependency-audit = "test-runner";
    module-lint = "test-runner";
    quick-check = "test-runner";
    refactor = "refactorer";
    review = "debugger";
    style-audit = "test-runner";
  };

  normalizeCommand =
    name: text:
    let
      parsed = parseFrontmatter text;
      inherit (parsed) attrs;
      agent = attrs.agent or (commandAgents.${name} or "explore");
    in
    {
      commandName = attrs.name or name;
      description = attrs.description or null;
      allowedTools = attrs."allowed-tools" or null;
      argumentHint = attrs."argument-hint" or null;
      prompt = parsed.content;
      inherit agent;
      model = attrs.model or (agentModelDefaults.${agent} or null);
      subtask = (attrs.subtask or false) == true || (attrs.subtask or "") == "true";
      original = text;
    };

  commands = lib.mapAttrs normalizeCommand rawCommands;

  renderClaudeFrontmatter =
    command:
    let
      model = modelValue "claude" command.model;
    in
    ''
      ---
      ${lib.optionalString (command.allowedTools != null) "allowed-tools: ${command.allowedTools}"}
      ${lib.optionalString (command.argumentHint != null) "argument-hint: ${command.argumentHint}"}
      ${lib.optionalString (command.description != null) "description: ${command.description}"}
      ${lib.optionalString (model != null) "model: ${model}"}
      ---
    '';

  renderClaudeMarkdown = command: ''
    ${lib.trim (renderClaudeFrontmatter command)}

    ${lib.trim command.prompt}
  '';

  renderOpenCodeFrontmatter =
    command:
    let
      model = modelValue "opencode" command.model;
    in
    ''
      ---
      ${lib.optionalString (command.description != null) "description: ${command.description}"}
      ${lib.optionalString (command.agent != null) "agent: ${command.agent}"}
      ${lib.optionalString (model != null) "model: ${model}"}
      ${lib.optionalString (command.subtask == true) "subtask: true"}
      ---
    '';

  renderOpenCodeMarkdown = command: ''
    ${lib.trim (renderOpenCodeFrontmatter command)}

    ${lib.trim command.prompt}
  '';

  renderCopilotSkill = command: ''
    ---
    name: ${builtins.toJSON command.commandName}
    description: ${builtins.toJSON (command.description or "AI command")}
    ---

    ${lib.trim command.prompt}
  '';

  renderCodexSkill = command: ''
    ---
    name: ${builtins.toJSON command.commandName}
    description: ${builtins.toJSON (command.description or "AI command")}
    ---

    ${lib.trim command.prompt}
  '';

  renderCodexSkillMetadata = _command: ''
    policy:
      allow_implicit_invocation: false
  '';

  renderCodexSkillFiles = command: {
    "SKILL.md" = renderCodexSkill command;
    "agents/openai.yaml" = renderCodexSkillMetadata command;
  };

  toClaudeMarkdown = lib.mapAttrs (_name: renderClaudeMarkdown) commands;
  toCopilotSkills = lib.mapAttrs (_name: renderCopilotSkill) commands;
  toCodexSkills = lib.mapAttrs (_name: renderCodexSkill) commands;
  toCodexSkillFiles = lib.mapAttrs (_name: renderCodexSkillFiles) commands;
  toOpenCodeMarkdown = lib.mapAttrs (_name: renderOpenCodeMarkdown) commands;
  toAntigravityCommands = lib.mapAttrs (_name: command: {
    inherit (command) prompt;
    description = command.description or "AI command";
  }) commands;
in
{
  inherit
    commands
    renderClaudeMarkdown
    renderCodexSkill
    renderCodexSkillFiles
    renderCodexSkillMetadata
    renderCopilotSkill
    renderOpenCodeMarkdown
    toAntigravityCommands
    toClaudeMarkdown
    toCodexSkillFiles
    toCodexSkills
    toCopilotSkills
    toOpenCodeMarkdown
    ;

  normalizedCommands = commands;
}
