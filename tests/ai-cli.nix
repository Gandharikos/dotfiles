# Evaluation only: no native configuration is read or written.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  check =
    base: enabled: integrations:
    let
      host = base.extendModules {
        modules = [
          {
            home-manager.users.johnson.my = {
              agy.enable = lib.mkForce enabled;
              claude-code.enable = lib.mkForce enabled;
              codex = {
                enable = lib.mkForce enabled;
                useHeadroom = lib.mkForce integrations;
              };
              opencode.enable = lib.mkForce enabled;
              pi.enable = lib.mkForce enabled;
              mcp.enable = lib.mkForce integrations;
              headroom.enable = lib.mkForce integrations;
              zlib.enable = lib.mkForce integrations;
            };
          }
        ];
      };
      home = host.config.home-manager.users.johnson;
      inherit (home.programs)
        antigravity-cli
        claude-code
        codex
        opencode
        pi-coding-agent
        ;
      tools = [
        antigravity-cli
        claude-code
        codex
        opencode
        pi-coding-agent
      ];
      targets = map (file: file.target) (builtins.attrValues home.home.file);
      unmanaged = [
        ".codex/config.toml"
        ".codex/AGENTS.md"
        ".pi/agent/settings.json"
        ".pi/agent/AGENTS.md"
        ".claude/settings.json"
        ".claude/CLAUDE.md"
        ".gemini/antigravity-cli/settings.json"
        ".gemini/AGENTS.md"
        "${home.xdg.configHome}/opencode/opencode.json"
        "${home.xdg.configHome}/opencode/cli.json"
        "${home.xdg.configHome}/opencode/tui.json"
        "${home.xdg.configHome}/opencode/AGENTS.md"
        "${home.xdg.configHome}/opencode/oh-my-openagent.json"
      ];
      hasTarget =
        path:
        let
          relative = lib.removePrefix "${home.home.homeDirectory}/" path;
        in
        builtins.elem relative targets || builtins.elem "${home.home.homeDirectory}/${relative}" targets;
    in
    assert builtins.all (tool: tool.enable == enabled) tools;
    assert enabled -> builtins.all (tool: tool.mutableSettings) tools;
    assert
      enabled
      -> builtins.all (tool: tool.enableMcpIntegration == integrations) [
        antigravity-cli
        claude-code
        codex
        opencode
      ];
    assert builtins.all (path: !hasTarget path) unmanaged;
    assert pi-coding-agent.settings == { };
    assert pi-coding-agent.context == "";
    assert antigravity-cli.settings == { };
    assert antigravity-cli.permissions == null;
    assert antigravity-cli.context == { } && antigravity-cli.commands == { };
    assert claude-code.context == "" && claude-code.agents == { } && claude-code.commands == { };
    assert codex.context == "" && codex.profiles == { } && codex.rules == { };
    assert
      claude-code.settings == (
        if enabled && integrations then { env.ANTHROPIC_BASE_URL = home.my.headroom.baseUrl; } else { }
      );
    assert
      builtins.attrNames codex.settings == (
        if enabled && integrations then
          [
            "model_provider"
            "model_providers"
          ]
        else
          [ ]
      );
    assert enabled && integrations -> codex.settings.model_provider == "headroom";
    assert enabled && integrations -> home.home.activation ? codexMutableSettings;
    assert enabled && integrations -> home.home.activation ? claudeCodeSettings;
    assert enabled && integrations -> home.home.activation ? antigravitySettings;
    assert !(home.home.activation ? piCodingAgentMutableSettings);
    assert opencode.settings == { } && opencode.tui == { } && opencode.cli == { };
    assert opencode.context == "" && opencode.agents == { } && opencode.commands == { };
    assert (home.home.sessionVariables ? OPENCODE_CONFIG) == (enabled && integrations);
    assert
      enabled && integrations
      ->
        home.home.sessionVariables.OPENCODE_CONFIG == "${home.xdg.configHome}/opencode/home-manager.json";
    assert hasTarget "${home.xdg.configHome}/opencode/home-manager.json" == (enabled && integrations);
    assert !(home.home.sessionVariables ? OPENCODE_TUI_CONFIG);
    assert !(home.home.sessionVariables ? OPENCODE_CLI_CONFIG_CONTENT);
    assert enabled -> lib.getVersion opencode.package == lib.getVersion host.pkgs.opencode;
    assert home.programs.github-copilot-cli.agents == { };
    assert
      (host.config.dot.services.hermes-agent.enable or false)
      -> host.config.services.hermes-agent.documents == { };
    true;
in
{
  darwinLocal = check flake.darwinConfigurations.eir true false;
  darwinIntegrations = check flake.darwinConfigurations.eir true true;
  linuxIntegrations = check flake.nixosConfigurations.ymir true true;
  disabled = check flake.darwinConfigurations.eir false false;
  disabledWithIntegrations = check flake.darwinConfigurations.eir false true;
}
