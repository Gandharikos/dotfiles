{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  cat' = getExe' pkgs.coreutils "cat";
  cfg = config.my.aichat;
in
{
  options.my.aichat = {
    enable = mkEnableOption "aichat";
  };

  config = mkIf cfg.enable {
    programs.aichat = {
      enable = true;
      settings = {
        save_session = true;
        stream = true;
        wrap = "auto";
        theme = "dark";
        wrap_code = true;
        highlight = true;
        keybindings = "vi";
        model = "ollama:mistral-small3.1:latest"; # ollama pull mistral-small3.1:latest
        rag_embedding_model = "ollama:RobinBially/nomic-embed-text-8k";
        clients = [
          {
            type = "openai-compatible";
            name = "openrouter";
            api_base = "https://openrouter.ai/api/v1";
            api_key_cmd = "${cat'} ${config.sops.secrets.openrouter_api_key.path}";
            models = [
              {
                name = "deepseek/deepseek-r1:free";
                type = "chat";
              }
            ];
          }
          {
            name = "ollama";
            type = "openai-compatible";
            api_base = "http://localhost:11434/v1";
            models = [
              {
                name = "mistral-small3.1:latest";
                supports_vision = true;
                supports_function_calling = true;
              }
              {
                name = "phind-codellama:latest";
                supports_vision = true;
                supports_function_calling = true;
              }
              {
                name = "phi:latest";
                supports_vision = true;
                supports_function_calling = true;
              }
            ];
          }
        ];
      };
    };
    sops.secrets.openrouter_api_key = { };
  };
}
