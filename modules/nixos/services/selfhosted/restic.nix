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
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (cfg.enable && cfg.backup == "restic") {
    environment.systemPackages = [ pkgs.restic ];

    services.restic.backups.selfhosted = {
      inherit (restic) repository;
      inherit (restic) passwordFile;
      initialize = true;
      paths = [ cfg.backups.exportDir ];
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
        ${exportPackage}/bin/selfhosted-export ${cfg.backups.exportDir}/selfhosted-latest.tar.zst
      '';
    };
  };
}
