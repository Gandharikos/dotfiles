{
  config,
  lib,
  pkgs,
  aiCommon,
  ...
}:
let
  cfg = config.my.codex;
  inherit (lib)
    getExe
    getExe'
    mkEnableOption
    mkOption
    mkIf
    optionalString
    optionals
    ;
  headroomEnabled = cfg.useHeadroom;
  mcpModuleEnabled = config.my.mcp.enable or false;
in
{
  options.my.codex = {
    enable = mkEnableOption "codex";
    useHeadroom = mkOption {
      type = lib.types.bool;
      default = config.my.headroom.enable or false;
      description = "Whether to use headroom token-compression proxy for Codex.";
    };
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
      enableMcpIntegration = mcpModuleEnabled;

      settings = {
        features = {
          apps = true;
          fast_mode = true;
          multi_agent = true;
          prevent_idle_sleep = true;
          shell_snapshot = true;
          skill_mcp_dependency_install = true;
          unified_exec = true;
          undo = true;
        };

        agents = {
          job_max_runtime_seconds = 3600;
          max_depth = 1;
          max_threads = 6;
        };

        history = {
          max_bytes = 104857600;
          persistence = "save-all";
        };

        model = "gpt-5.5";
        model_provider = mkIf headroomEnabled "headroom";
        model_providers = mkIf headroomEnabled {
          headroom = {
            name = "Headroom";
            base_url = config.my.headroom.openaiBaseUrl;
            env_key = "OPENAI_API_KEY";
            wire_api = "responses";
          };
        };
        model_reasoning_effort = "high";
        plan_mode_reasoning_effort = "xhigh";
        service_tier = "fast";

        notify =
          let
            codexNotify = pkgs.writeShellApplication {
              name = "codex-notify";
              runtimeInputs = [
                pkgs.coreutils
                pkgs.jq
              ]
              ++ optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libnotify ]
              ++ optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.terminal-notifier ];
              text = ''
                payload="$1"
                eventType="$(printf '%s' "$payload" | jq -r '.type // ""')"
                [ "$eventType" = "agent-turn-complete" ] || exit 0

                message="$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // "Turn complete"')"
                summary="$(printf '%s' "$message" | cut -c1-180)"

                ${optionalString pkgs.stdenv.hostPlatform.isDarwin ''
                  ${getExe pkgs.terminal-notifier} -title "Codex" -message "$summary" -group "codex-turn" >/dev/null 2>&1
                ''}
                ${optionalString pkgs.stdenv.hostPlatform.isLinux ''
                  ${getExe' pkgs.libnotify "notify-send"} "Codex" "$summary" >/dev/null 2>&1
                ''}
              '';
            };
          in
          [ (getExe codexNotify) ];

        personality = "pragmatic";

        project_root_markers = [
          ".git"
          ".jj"
          ".hg"
          ".sl"
        ];

        approval_policy = "on-request";
        sandbox_mode = "danger-full-access";

        tui.status_line = [
          "model-with-reasoning"
          "current-dir"
          "context-remaining"
          "context-used"
          "five-hour-limit"
        ];

        projects = {
          "${config.home.homeDirectory}/.dotfiles" = {
            trust_level = "trusted";
          };
          "${config.home.homeDirectory}/Dev/Projects" = {
            trust_level = "trusted";
          };
        };
      };

      profiles = {
        deep = {
          model = "gpt-5.4";
          model_auto_compact_token_limit = 900000;
          model_context_window = 1050000;
          model_reasoning_effort = "high";
          model_verbosity = "high";
          plan_mode_reasoning_effort = "xhigh";
          web_search = "live";
        };

        nano = {
          model = "gpt-5.4-nano";
          model_reasoning_effort = "none";
          model_verbosity = "low";
          plan_mode_reasoning_effort = "low";
          service_tier = "flex";
          web_search = "disabled";
        };

        offline = {
          sandbox_workspace_write.network_access = false;
          web_search = "disabled";
        };

        quick = {
          model = "gpt-5.3-codex-spark";
          model_reasoning_effort = "medium";
          model_reasoning_summary = "none";
          model_verbosity = "low";
          plan_mode_reasoning_effort = "medium";
          service_tier = "fast";
          web_search = "disabled";
        };

        spark = {
          model = "gpt-5.3-codex-spark";
          model_reasoning_effort = "medium";
          model_verbosity = "medium";
          plan_mode_reasoning_effort = "high";
          service_tier = "fast";
          web_search = "disabled";
        };

        unsafe = {
          approval_policy = "on-request";
          sandbox_mode = "danger-full-access";
          shell_environment_policy.ignore_default_excludes = true;
        };
      };

      inherit (aiCommon.codex) skills context;
      rules = import ./rules.nix;
    };
  };
}
