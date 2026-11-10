{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.opencode;
in
{
  options.my.opencode.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf cfg.enable {
    sops.secrets.openrouter_api_key = { };

    programs.opencode = {
      enable = true;
      mutableSettings = true;
      enableMcpIntegration = config.my.mcp.enable or false;
      package = pkgs.writeShellApplication {
        name = "opencode";
        meta = pkgs.opencode.meta;
        derivationArgs = { inherit (pkgs.opencode) version; };
        text = ''
          OPENROUTER_API_KEY="$(${lib.getExe' pkgs.coreutils "cat"} ${lib.escapeShellArg config.sops.secrets.openrouter_api_key.path})"
          export OPENROUTER_API_KEY
          exec ${lib.getExe pkgs.opencode} "$@"
        '';
      };
    };
  };
}
