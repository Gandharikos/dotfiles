{
  self,
  inputs,
  config,
  lib,
  pkgs,
  aiCommon,
  ...
}: let
  cfg = config.my.gemini-cli;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.home) homeDirectory;
  inherit (config.my) name;
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
in {
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
        package = inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli;
        settings = {
          ui.theme = "Default";
          general = {
            vimMode = true;
            preferredEditor = "nvim";
          };
          tools.autlAccept = false;
          security.auth.selectedType = "oauth-personal";
        };
        context = {
          GEMINI = lib.my.getFile "modules/home/cli/ai/common/base.md";
        };

        commands =
          sharedAiTools.geminiCli.commands
          // sharedAiTools.geminiCli.agents;
      };
    };

    home = {
      persistence."/persist".directories = [
        ".gemini"
      ];
    };

    sops.secrets = {
      "gemini-oauth_creds" = {
        sopsFile = "${self}/secrets/${name}/gemini-oauth_creds";
        path = "${homeDirectory}/.gemini/oauth_creds.json";
        mode = "0400";
        format = "binary";
      };
      "gemini-google_accounts" = {
        sopsFile = "${self}/secrets/${name}/gemini-google_accounts";
        path = "${homeDirectory}/.gemini/google_accounts.json";
        mode = "0400";
        format = "binary";
      };
    };
  };
}
