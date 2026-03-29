{
  config,
  lib,
  pkgs,
  aiCommon,
  ...
}:
let
  cfg = config.my.gemini-cli;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  # inherit (lib.meta) getExe';
  # cat' = getExe' pkgs.coreutils "cat";
  # cloudProjectPath = config.sops.secrets.google_cloud_project.path;
  # apiKeyPath = config.sops.secrets.gemini_api_key.path;
  #
  # tokenExportShell = ''
  #   if [ -f ${cloudProjectPath} ]; then
  #     export GOOGLE_CLOUD_PROJECT="$(${cat'} ${cloudProjectPath})"
  #   fi
  #   if [ -f ${apiKeyPath} ]; then
  #     export GEMINI_API_KEY="$(${cat'} ${apiKeyPath})"
  #   fi
  # '';
  sharedAiTools = aiCommon;
in
{
  options.my.gemini-cli = {
    enable = mkEnableOption "gemini-cli";
  };

  config = mkIf cfg.enable {
    programs = {
      # bash.initExtra = tokenExportShell;
      # fish.shellInit = ''
      #   if test -f ${cloudProjectPath}
      #     set -x GOOGLE_CLOUD_PROJECT (${cat'} ${cloudProjectPath})
      #   end
      #   if test -f ${apiKeyPath}
      #     set -x GEMINI_API_KEY (${cat'} ${apiKeyPath})
      #   end
      # '';
      # zsh.initContent = tokenExportShell;
      gemini-cli = {
        enable = true;
        # build error on darwin
        package = pkgs.llm-agents.gemini-cli;
        settings = {
          contextFilename = "AGENTS.md";

          context = {
            discoveryMaxDirs = 1000;
            # NOTE: bombs out on repos that don't have them
            # includeDirectories = [
            #   "lib"
            #   "modules"
            #   "docs"
            # ];
            loadMemoryFromIncludeDirectories = true;
            fileFiltering = {
              enableFuzzySearch = true;
              enableRecursiveFileSearch = true;
              respectGeminiIgnore = true;
              respectGitIgnore = true;
            };
          };
          ui = {
            footer.hideContextPercentage = false;
            inlineThinkingMode = "full";
            showCitations = true;
            showModelInfoInChat = true;
            showStatusInTitle = true;
            useAlternateBuffer = true;
            showMemoryUsage = true;
            theme = lib.mkDefault "Default";
          };
          ide.enabled = true;
          privacy.usageStatisticsEnabled = false;
          general = {
            checkpointing = {
              enabled = true;
            };
            enablePromptCompletion = true;
            preferredEditor = "neovim";
            previewFeatures = true;
            sessionRetention = {
              enabled = true;
              maxAge = "30d";
              maxCount = 100;
            };
            vimMode = true;
            plan = {
              modelRouting = true;
            };
          };
          tools = {
            autoAccept = false;
            shell.showColor = true;
            useRipgrep = true;
            truncateToolOutputThreshold = 50000;
          };
          security = {
            auth.selectedType = "oauth-personal";
            folderTrust.enabled = true;
            environmentVariableRedaction.enabled = true;
          };

          experimental = {
            plan = true;
            taskTracker = true;
            modelSteering = true;
            toolOutputMasking = {
              enabled = true;
              protectLatestTurn = true;
            };
          };
        };
        context = {
          AGENTS = lib.my.getFile "modules/home/cli/ai/common/base.md";
        };

        commands = sharedAiTools.geminiCli.commands // sharedAiTools.geminiCli.agents;
      };
    };
  };
}
