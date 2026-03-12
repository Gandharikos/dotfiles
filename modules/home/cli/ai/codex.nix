{
  self,
  config,
  lib,
  pkgs,
  aiCommon,
  ...
}: let
  cfg = config.my.codex;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.home) homeDirectory;
  inherit (config.my) name;
in {
  options.my.codex = {
    enable = mkEnableOption "codex";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
      package = pkgs.llm-agents.codex;
      custom-instructions = aiCommon.codex.customInstructions;
      inherit (aiCommon.codex) skills;
    };

    sops.secrets."codex-auth" = {
      sopsFile = "${self}/secrets/${name}/codex-auth";
      path = "${homeDirectory}/.codex/auth.json";
      mode = "0400";
      format = "binary";
    };
  };
}
