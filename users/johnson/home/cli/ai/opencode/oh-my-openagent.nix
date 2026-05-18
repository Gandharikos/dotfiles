{
  config,
  lib,
  pkgs,
  aiCommon,
  ...
}:
let
  cfg = config.my.opencode;
  json = pkgs.formats.json { };

  mainModel = "openai/gpt-5.4";
  nanoModel = "openai/gpt-5.4-nano";
  quickModel = "openai/gpt-5.3-codex-spark";

  deliberateFallbackModels = [
    "openai/gpt-5.3-codex"
    quickModel
  ];

  fastFallbackModels = [
    quickModel
    nanoModel
  ];
in
{
  options.my.opencode.ohMyOpenAgent.settings = lib.mkOption {
    inherit (json) type;
    default = { };
    description = ''
      Raw Oh My OpenAgent configuration written to
      {file}`$XDG_CONFIG_HOME/opencode/oh-my-openagent.json`.

      This is separate from {option}`programs.opencode.settings`, which configures
      OpenCode itself. The shared defaults here are tailored for this dotfiles
      repo and can be recursively overridden.
    '';
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."opencode/oh-my-openagent.json".source = json.generate "oh-my-openagent.json" (
      lib.recursiveUpdate {
        "$schema" =
          "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

        agents = {
          sisyphus = {
            model = mainModel;
            fallback_models = deliberateFallbackModels;
            prompt_append = "Follow the repository engineering rules already provided through the shared OpenCode context. Prefer the shared commands and skills before inventing new workflows.";
          };
          oracle = {
            model = mainModel;
            fallback_models = deliberateFallbackModels;
          };
          explore = {
            model = quickModel;
            fallback_models = fastFallbackModels;
          };
          librarian = {
            model = quickModel;
            fallback_models = fastFallbackModels;
          };
        };

        categories = {
          quick = {
            model = quickModel;
            fallback_models = [
              nanoModel
              mainModel
            ];
            description = "Fast, minimal edits and low-surface changes.";
          };
          deep = {
            model = mainModel;
            fallback_models = deliberateFallbackModels;
            description = "Debugging, diagnosis, and deliberate investigation.";
          };
          unspecified-high = {
            model = mainModel;
            fallback_models = deliberateFallbackModels;
            description = "General engineering work that benefits from stronger reasoning.";
          };
          unspecified-low = {
            model = quickModel;
            fallback_models = fastFallbackModels;
            description = "Cheaper general subtasks and verification work.";
          };
          writing = {
            model = quickModel;
            fallback_models = [
              nanoModel
              mainModel
            ];
            description = "Documentation and prose-heavy tasks.";
          };
        };

        disabled_skills = [
          "frontend-ui-ux"
          "git-master"
          "playwright"
          "playwright-cli"
        ];

        background_task = {
          providerConcurrency = {
            github-copilot = 8;
            openai = 3;
          };
          modelConcurrency = {
            "openai/gpt-5.4" = 2;
            "github-copilot/gpt-5-mini" = 12;
          };
        };

        git_master = {
          commit_footer = false;
          include_co_authored_by = false;
        };

        runtime_fallback = true;

        model_capabilities = {
          enabled = true;
          auto_refresh_on_start = true;
          refresh_timeout_ms = 5000;
        };

        skills.sources = [
          {
            path = toString aiCommon.skillsDir;
            recursive = true;
          }
        ];

        experimental = {
          task_system = true;
          dynamic_context_pruning = {
            enabled = true;
            notification = "minimal";
            turn_protection = {
              enabled = true;
              turns = 3;
            };
          };
        };
      } cfg.ohMyOpenAgent.settings
    );
  };
}
