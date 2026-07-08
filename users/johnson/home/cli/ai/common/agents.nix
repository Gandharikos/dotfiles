{ lib, ... }:
let
  rawAgents = import ./agents { inherit lib; };

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

  normalizeAgent =
    name: text:
    let
      parsed = parseFrontmatter text;
      inherit (parsed) attrs;
    in
    {
      name = attrs.name or name;
      description = attrs.description or "AI agent: ${name}";
      tools = attrs.tools or null;
      model = attrs.model or null;
      model_reasoning_effort = attrs.model_reasoning_effort or null;
      sandbox_mode = attrs.sandbox_mode or null;
      inherit (parsed) content;
      original = text;
    };

  agents = lib.mapAttrs normalizeAgent rawAgents;

  renderClaudeFrontmatter =
    agent:
    let
      model = modelValue "claude" agent.model;
    in
    ''
      ---
      name: ${agent.name}
      description: ${agent.description}
      ${lib.optionalString (agent.tools != null) "tools: ${agent.tools}"}
      ${lib.optionalString (model != null) "model: ${model}"}
      ---
    '';

  renderClaudeAgent = agent: ''
    ${lib.trim (renderClaudeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderOpenCodeTools =
    agent:
    if agent.tools == null then
      ""
    else
      let
        allowed = map lib.toLower (map lib.trim (lib.splitString "," agent.tools));
        isAllowed = tool: lib.elem tool allowed;
        coreTools = [
          "bash"
          "edit"
          "write"
        ];
        coreToolLines = map (tool: "  ${tool}: ${if isAllowed tool then "true" else "false"}") coreTools;
      in
      ''
        tools:
        ${lib.concatStringsSep "\n" coreToolLines}
      '';

  renderOpenCodeFrontmatter =
    agent:
    let
      model = modelValue "opencode" agent.model;
    in
    ''
      ---
      description: ${agent.description}
      ${lib.optionalString (model != null) "model: ${model}"}
      ${renderOpenCodeTools agent}
      ---
    '';

  renderOpenCodeAgent = agent: ''
    ${lib.trim (renderOpenCodeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderCopilotFrontmatter =
    agent:
    let
      model = modelValue "copilot" agent.model;
    in
    ''
      ---
      name: ${builtins.toJSON agent.name}
      description: ${builtins.toJSON agent.description}
      ${lib.optionalString (model != null) "model: ${builtins.toJSON model}"}
      ---
    '';

  renderCopilotAgent = agent: ''
    ${lib.trim (renderCopilotFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderCodexAgent =
    agent:
    let
      model = modelValue "codex" agent.model;
      modelReasoningEffort = modelValue "codex" (agent.model_reasoning_effort or null);
      sandboxMode = modelValue "codex" (agent.sandbox_mode or null);
    in
    {
      inherit (agent) name description;
      developer_instructions = lib.trim agent.content;
    }
    // lib.optionalAttrs (model != null) {
      inherit model;
    }
    // lib.optionalAttrs (modelReasoningEffort != null) {
      model_reasoning_effort = modelReasoningEffort;
    }
    // lib.optionalAttrs (sandboxMode != null) {
      sandbox_mode = sandboxMode;
    };

  toClaudeMarkdown = lib.mapAttrs (_name: renderClaudeAgent) agents;
  toCopilotMarkdown = lib.mapAttrs (_name: renderCopilotAgent) agents;
  toAntigravityAgents = lib.mapAttrs (_name: agent: {
    prompt = agent.content;
    description = agent.description or "AI agent";
  }) agents;
  renderAntigravitySkill = agent: ''
    ---
    name: ${builtins.toJSON agent.name}
    description: ${builtins.toJSON agent.description}
    ---

    ${lib.trim agent.content}
  '';
  toAntigravitySkills = lib.mapAttrs (_name: renderAntigravitySkill) agents;
  toCodexAgents = lib.mapAttrs (_name: renderCodexAgent) agents;
  toOpenCodeMarkdown = lib.mapAttrs (_name: renderOpenCodeAgent) agents;
in
{
  inherit
    agents
    renderAntigravitySkill
    renderClaudeAgent
    renderCopilotAgent
    renderOpenCodeAgent
    toAntigravityAgents
    toAntigravitySkills
    toClaudeMarkdown
    toCodexAgents
    toCopilotMarkdown
    toOpenCodeMarkdown
    ;
}
