{ inputs, ... }:
{
  ai =
    final: _prev:
    let
      system = final.stdenv.hostPlatform.system;
      llmAgentPackages = inputs.llm-agents.packages.${system};
      hermesDesktopElectronHeadersHash = "sha256-zOl8rx6woWh7aeRUOlkTMviKc/EAQQX6nr/MxAx1ZPI=";
      hermesDesktopPkgs = final // {
        fetchurl =
          args:
          final.fetchurl (
            args
            //
              final.lib.optionalAttrs
                (args.url == "https://artifacts.electronjs.org/headers/dist/v41.9.1/node-v41.9.1-headers.tar.gz")
                {
                  sha256 = hermesDesktopElectronHeadersHash;
                }
          );
      };
    in
    {
      inherit (llmAgentPackages)
        claude-desktop
        cursor-agent
        qwen-code
        ;

      github-copilot-cli = llmAgentPackages.copilot-cli;
      codex-desktop = inputs.codex-desktop-linux.packages.${system}.codex-desktop;
      hermes-desktop = inputs.hermes-agent.packages.${system}.desktop.override {
        pkgs = hermesDesktopPkgs;
      };
      inherit (llmAgentPackages) hermes-hud;
    };
}
