{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.machine;
in
{
  options.my.machine.hasTPM = mkEnableOption "Whether the system has tpm support";

  config = mkIf cfg.hasTPM {
    security.tpm2 = {
      # enable Trusted Platform Module 2 support
      enable = true;

      # enable Trusted Platform 2 usersapce resource manager daemon
      abrmd.enable = false;

      # set TCTI environment variables to the specified values if enabled
      # - TPM2TOOL5_TCTI
      # - TPM2_PKCS11_TCTI
      tctiEnvironment.enable = true;

      # enable TPM2 PKCS#11 tool and shared library in system path
      pkcs11.enable = true;
    };

    boot.initrd.kernelModules = [ "tpm" ];
  };
}
