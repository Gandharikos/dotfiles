{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  sharedAiTools = import (lib.my.getFile "modules/home/cli/ai/common/shared.nix") {inherit lib;};

  cfg = config.my.opencode;
in {
  imports = lib.my.scanPaths ./.;

  options.my.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      package = inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

      settings = {
        theme = "opencode";
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;
      };

      inherit (sharedAiTools.claudeCode) agents;
      inherit (sharedAiTools.claudeCode) commands;

      rules = builtins.readFile (lib.my.getFile "modules/home/cli/ai/common/base.md");
    };

    home.persistence."/persist".directories = [
      ".config/opencode"
    ];
  };
}
