{ inputs, ... }:
{
  ai =
    final: _prev:
    let
      system = final.stdenv.hostPlatform.system;
      llmAgentPackages = inputs.llm-agents.packages.${system};
    in
    {
      inherit (llmAgentPackages)
        claude-desktop
        cursor-agent
        qwen-code
        ;

      github-copilot-cli = llmAgentPackages.copilot-cli;
      codex-desktop = inputs.codex-desktop-linux.packages.${system}.codex-desktop;
      hermes-desktop = inputs.hermes-agent.packages.${system}.desktop;
      inherit (llmAgentPackages) hermes-hud;
    };
}
