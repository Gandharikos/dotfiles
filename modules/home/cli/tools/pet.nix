{
  lib,
  config,
  ...
}:
let
  cfg = config.my.pet;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.pet.enable = mkEnableOption "Pet tool";

  config = mkIf cfg.enable {
    programs.pet = {
      enable = true;
      settings = {
        General = {
          editor = "nvim";
          selectcmd = "fzf --ansi";
          sortby = "command";
          color = true;
          format = "$command | $description | $tags |";
        };
      };
      snippets = [
        {
          command = "sudo lsof -nP -iTCP -sTCP:LISTEN";
          description = "Show services which listen to any TCP port";
          tag = [
            "cmd"
            "networking"
            "system"
          ];
        }
        {
          command = "journalctl -b -p err --no-pager";
          description = "Show boot errors from the current boot";
          tag = [
            "cmd"
            "system"
            "logs"
          ];
        }
        {
          command = "sudo ssh-keygen -A";
          description = "Generate any missing SSH host keys";
          tag = [
            "cmd"
            "ssh"
            "system"
          ];
        }
        {
          command = "git log --all --stat --";
          description = "Show Git history for a specific path";
          tag = [
            "cmd"
            "git"
            "history"
          ];
        }
        {
          command = "git log -p --";
          description = "Show commit history with patches for a specific path";
          tag = [
            "cmd"
            "git"
            "history"
          ];
        }
        {
          command = "sops --in-place set secrets/services/default.yaml '[\"my_key\"]' '\"my-secret-value\"'";
          description = "Set a string secret in secrets/services/default.yaml directly";
          tag = [
            "cmd"
            "sops"
            "secrets"
          ];
        }
        {
          command = "printf '%s' '\"my-secret-value\"' | sops --in-place set --value-stdin secrets/services/default.yaml '[\"my_key\"]'";
          description = "Set a string secret in secrets/services/default.yaml from stdin";
          tag = [
            "cmd"
            "sops"
            "secrets"
          ];
        }
        {
          command = "jq -Rn --arg v \"$SECRET\" '$v' | sops --in-place set --value-stdin secrets/services/default.yaml '[\"my_key\"]'";
          description = "Set a string secret from the SECRET environment variable";
          tag = [
            "cmd"
            "sops"
            "secrets"
          ];
        }
        {
          command = "jq -nc --arg token \"$TOKEN\" --arg url \"$URL\" '{ token: $token, url: $url }' | sops --in-place set --value-stdin secrets/services/default.yaml '[\"mihomo\"]'";
          description = "Set a nested object secret in secrets/services/default.yaml";
          tag = [
            "cmd"
            "sops"
            "secrets"
          ];
        }
      ];
    };
  };
}
