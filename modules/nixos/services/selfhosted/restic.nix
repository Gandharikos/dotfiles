{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted;
  restic = cfg.backups.restic;
  exportPackage = lib.dot.mkSelfhostedExportPackage pkgs;
  taildropPackage = lib.dot.mkSelfhostedTaildropPackage pkgs config;
  backupPathsFile = pkgs.writeText "selfhosted-backup-paths" (lib.concatLines cfg.backups.paths);
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (cfg.enable && cfg.backup == "restic") {
    environment.systemPackages = [ pkgs.restic ];

    services.restic.backups.selfhosted = {
      inherit (restic) repository;
      inherit (restic) passwordFile;
      initialize = true;
      paths = [ ];
      dynamicFilesFrom = ''
        while IFS= read -r path; do
          [ -e "$path" ] && printf '%s\n' "$path"
        done < ${backupPathsFile}
      '';
      timerConfig = {
        OnCalendar = cfg.backups.schedule;
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
      inherit (restic) pruneOpts;
      backupPrepareCommand = ''
        install -d -m 0700 ${cfg.backups.exportDir} "$(dirname ${restic.passwordFile})" "$(dirname ${restic.repository})"
        if [ ! -s ${restic.passwordFile} ]; then
          umask 077
          ${pkgs.openssl}/bin/openssl rand -base64 48 > ${restic.passwordFile}
        fi
        ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dumpall \
          | ${pkgs.zstd}/bin/zstd -T0 -19 -o ${cfg.backups.postgresqlDumpFile}.tmp > /dev/null
        mv ${cfg.backups.postgresqlDumpFile}.tmp ${cfg.backups.postgresqlDumpFile}
        ${exportPackage}/bin/selfhosted-export ${cfg.backups.exportDir}/selfhosted-latest.tar.zst
      '';
    };

    systemd.services.restic-backups-selfhosted = {
      onFailure = mkIf cfg.services.ntfy.enable [ "selfhosted-backup-alert@%n.service" ];
      serviceConfig.ExecStartPost = [
        "${
          pkgs.writeShellApplication {
            name = "selfhosted-restic-mark-success";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              install -d -m 0700 /var/lib/selfhosted-backup
              date +%s > /var/lib/selfhosted-backup/last-success
              printf 'restic\n' > /var/lib/selfhosted-backup/last-method
            '';
          }
        }/bin/selfhosted-restic-mark-success"
      ]
      ++ lib.optional cfg.backups.taildrop.enable "${taildropPackage}/bin/selfhosted-taildrop-backup";
    };
  };
}
