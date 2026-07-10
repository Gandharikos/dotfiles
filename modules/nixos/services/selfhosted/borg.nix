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
  taildropPackage = lib.dot.mkSelfhostedTaildropPackage pkgs config;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (cfg.enable && cfg.backup == "borg") {
    environment.systemPackages = [ pkgs.borgbackup ];

    services.borgbackup.jobs.selfhosted = {
      repo = borg.repository;
      paths = cfg.backups.paths;
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/lib/selfhosted-backup/borg-passphrase";
      };
      compression = "auto,zstd";
      startAt = cfg.backups.schedule;
      persistentTimer = true;
      readWritePaths = [
        "/var/backup"
        "/var/lib/selfhosted-backup"
      ];
      prune.keep = borg.pruneKeep;
      preHook = ''
        install -d -m 0700 ${cfg.backups.exportDir} "$(dirname ${borg.repository})" /var/lib/selfhosted-backup ${builtins.dirOf cfg.backups.postgresqlDumpFile}
        if [ ! -s /var/lib/selfhosted-backup/borg-passphrase ]; then
          umask 077
          ${lib.getExe' pkgs.openssl "openssl"} rand -base64 48 > /var/lib/selfhosted-backup/borg-passphrase
        fi
        ${lib.getExe' pkgs.util-linux "runuser"} -u postgres -- ${lib.getExe' config.services.postgresql.package "pg_dumpall"} \
          | ${lib.getExe' pkgs.zstd "zstd"} -T0 -19 -o ${cfg.backups.postgresqlDumpFile}.tmp > /dev/null
        mv ${cfg.backups.postgresqlDumpFile}.tmp ${cfg.backups.postgresqlDumpFile}
        ${lib.getExe' exportPackage "selfhosted-export"} ${cfg.backups.exportDir}/selfhosted-latest.tar.zst
      '';
      postCreate = ''
        install -d -m 0700 /var/lib/selfhosted-backup
        date +%s > /var/lib/selfhosted-backup/last-success
        printf 'borg\n' > /var/lib/selfhosted-backup/last-method
        ${lib.optionalString cfg.backups.taildrop.enable "${lib.getExe' taildropPackage "selfhosted-taildrop-backup"}"}
      '';
    };

    systemd.services.borgbackup-job-selfhosted.onFailure = mkIf cfg.services.ntfy.enable [
      "selfhosted-backup-alert@%n.service"
    ];
  };
}
