{ config, lib, ... }:
let
  cfg = config.my.codex;
in
{
  options.my.codex = {
    enable = lib.mkEnableOption "codex";
    useHeadroom = lib.mkOption {
      type = lib.types.bool;
      default = config.my.headroom.enable or false;
      description = "Whether to use headroom token-compression proxy for Codex.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.codex = {
      enable = true;
      mutableSettings = true;
      enableMcpIntegration = config.my.mcp.enable or false;

      # Only integration settings are managed; preferences live in config.toml.
      settings = lib.mkIf cfg.useHeadroom {
        model_provider = "headroom";
        model_providers.headroom = {
          name = "Headroom";
          base_url = config.my.headroom.openaiBaseUrl;
          env_key = "OPENAI_API_KEY";
          wire_api = "responses";
        };
      };
    };
  };
}
