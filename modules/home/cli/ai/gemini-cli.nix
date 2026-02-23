{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.gemini-cli;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  cat' = getExe' pkgs.coreutils "cat";
  cloudProjectPath = config.sops.secrets.google_cloud_project.path;
  apiKeyPath = config.sops.secrets.gemini_api_key.path;

  tokenExportShell = ''
    if [ -f ${cloudProjectPath} ]; then
      export GOOGLE_CLOUD_PROJECT="$(${cat'} ${cloudProjectPath})"
    fi
    if [ -f ${apiKeyPath} ]; then
      export GEMINI_API_KEY="$(${cat'} ${apiKeyPath})"
    fi
  '';
  sharedAiTools = import (lib.my.getFile "modules/home/cli/ai/common/shared.nix") {inherit lib;};
in {
  options.my.gemini-cli = {
    enable = mkEnableOption "gemini-cli";
  };

  config = mkIf cfg.enable {
    programs = {
      bash.initExtra = tokenExportShell;
      fish.shellInit = ''
        if test -f ${cloudProjectPath}
          set -x GOOGLE_CLOUD_PROJECT (${cat'} ${cloudProjectPath})
        end
        if test -f ${apiKeyPath}
          set -x GEMINI_API_KEY (${cat'} ${apiKeyPath})
        end
      '';
      zsh.initContent = tokenExportShell;
      gemini-cli = {
        enable = true;
        package = inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli;
        settings = {
          ui.theme = "Default";
          general = {
            vimMode = true;
            preferredEditor = "nvim";
          };
          tools.autlAccept = false;
        };
        defaultModel = "gemini-2.5-pro";
        context = {
          GEMINI = lib.my.getFile "modules/home/cli/ai/common/base.md";
        };

        commands =
          sharedAiTools.geminiCli.commands
          // sharedAiTools.geminiCli.agents
          // {
            changelog = {
              prompt = ''
                Your task is to parse the version, change type, and message from the input
                and update the CHANGELOG.md file accordingly following
                conventional commit standards.
              '';
              description = "Update CHANGELOG.md with new entry following conventional commit standards";
            };

            review = {
              prompt = ''
                Analyze the staged git changes and provide a thorough
                code review with suggestions for improvement, focusing on
                code quality, security, and maintainability.
              '';
              description = "Analyze staged git changes and provide thorough code review";
            };

            "git/commit-msg" = {
              prompt = ''
                Generate a conventional commit message based on the
                staged changes, following the project's commit standards.
                Analyze the changes and create an appropriate commit message.
              '';
              description = "Generate conventional commit message based on staged changes";
            };
          };
      };
    };

    home = {
      persistence."/persist".directories = [
        ".gemini"
      ];
    };

    sops.secrets = {
      google_cloud_project = {};
      gemini_api_key = {};
    };
  };
}
