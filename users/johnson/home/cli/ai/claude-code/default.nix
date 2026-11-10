{ config, lib, ... }:
let
  cfg = config.my.claude-code;
in
{
  options.my.claude-code.enable = lib.mkEnableOption "claude-code";

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      mutableSettings = true;
      enableMcpIntegration = config.my.mcp.enable or false;

      # Only integration settings are managed; preferences live in settings.json.
      settings.env = lib.mkIf (config.my.headroom.enable or false) {
        ANTHROPIC_BASE_URL = config.my.headroom.baseUrl;
      };
    };
  };
}
