{ lib, ... }:
let
  agents = import ./agents { inherit lib; };

  toAntigravityAgents = lib.mapAttrs (
    name: agentText:
    let
      parts = lib.splitString "---" agentText;
      mainContent = if lib.length parts >= 3 then lib.elemAt parts 2 else agentText;
      frontmatter = if lib.length parts >= 2 then lib.elemAt parts 1 else "";
      descMatch = lib.optionals (lib.hasInfix "description:" frontmatter) [
        (lib.removePrefix "description: " (
          lib.trim (
            lib.head (lib.filter (line: lib.hasPrefix "description:" line) (lib.splitString "\n" frontmatter))
          )
        ))
      ];
      description = if descMatch != [ ] then lib.head descMatch else "AI agent: ${name}";
    in
    {
      prompt = lib.trim mainContent;
      inherit description;
    }
  ) agents;
in
{
  inherit agents;

  toClaudeMarkdown = agents;
  toOpenCodeMarkdown = agents;
  inherit toAntigravityAgents;
}
