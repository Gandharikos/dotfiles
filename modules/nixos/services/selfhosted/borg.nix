{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted;
  borg = cfg.backups.borg;
  exportPackage = lib.dot.mkSelfhostedExportPackage pkgs;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (cfg.enable && cfg.backup == "borg") {
    environment.systemPackages = [ pkgs.borgbackup ];

    services.borgbackup.jobs.selfhosted = {
      repo = borg.repository;
      paths = [ cfg.backups.exportDir ];
      doInit = true;
      encryption.mode = "none";
      compression = "auto,zstd";
      startAt = cfg.backups.schedule;
      persistentTimer = true;
      readWritePaths = [ "/var/backup" ];
      prune.keep = borg.pruneKeep;
      preHook = ''
        install -d -m 0700 ${cfg.backups.exportDir} "$(dirname ${borg.repository})"
        ${exportPackage}/bin/selfhosted-export ${cfg.backups.exportDir}/selfhosted-latest.tar.zst
      '';
    };
  };
}
