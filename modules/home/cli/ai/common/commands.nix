{ lib, ... }:
let
  commands = import ./commands { inherit lib; };

  toGeminiCommands = lib.mapAttrs (name: prompt: {
    inherit prompt;
    description =
      let
        lines = lib.splitString "\n" prompt;
        descLine = lib.findFirst (line: lib.hasPrefix "description:" line) "" lines;
      in
      if descLine != "" then
        lib.removePrefix "description: " (lib.trim descLine)
      else
        "AI command: ${name}";
  }) commands;
in
{
  inherit commands;

  toClaudeMarkdown = commands;
  toOpenCodeMarkdown = commands;
  inherit toGeminiCommands;
}
