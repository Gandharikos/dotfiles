{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.meta) getExe;
  curl' = getExe pkgs.curl;
in
{
  imports = lib.dot.scanPaths ./.;
  config.home = {
    shellAliases = {
      syslog = "journalctl -f";
      sysfail = "systemctl --failed";
      sysreload = "sudo systemctl daemon-reload";

      # Process monitoring
      psmem = "ps aux | sort -nr -k 4 | head -10";
      pscpu = "ps aux | sort -nr -k 3 | head -10";

      # Disk usage
      dush = "du -sh * | sort -hr";
      dfh = "df -h | grep -v tmpfs";

      weather = "${curl'} wttr.in";
    };
    sessionVariables.KEYBOARD_LAYOUT = config.dot.keyboard.layout;
  };
}
