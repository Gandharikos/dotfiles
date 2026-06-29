{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) port str;
  cfg = config.my.headroom;
  package = pkgs.dot.headroom;
in
{
  options.my.headroom = {
    enable = mkEnableOption "headroom token-compression proxy for AI coding agents";

    host = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "Address the local Headroom proxy binds to.";
    };

    port = mkOption {
      type = port;
      default = 8787;
      description = "Port the local Headroom proxy listens on.";
    };

    baseUrl = mkOption {
      type = str;
      default = "http://${cfg.host}:${toString cfg.port}";
      readOnly = true;
      description = "Base URL clients (e.g. claude-code) point ANTHROPIC_BASE_URL at.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    # Always-on local proxy. Claude Code reaches it via ANTHROPIC_BASE_URL,
    # which is wired up in the claude-code module when my.headroom.enable is set.
    systemd.user.services.headroom = {
      Unit = {
        Description = "Headroom token-compression proxy for AI coding agents";
        Documentation = [ "https://github.com/chopratejas/headroom" ];
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        ExecStart = "${package}/bin/headroom proxy --host ${cfg.host} --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = 5;
        # First run downloads ~500MB of compression models into ~/.cache.
        TimeoutStartSec = "infinity";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
