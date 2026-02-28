{
  config,
  lib,
  ...
}: let
  sudoCfg = config.my.security.sudo;
  inherit (lib.modules) mkDefault;
  pamInclude = ''
    auth include login
    account include login
    session include login
  '';
in {
  security.pam = {
    # fix "too many files open" errors while writing a lot of data at once
    # (e.g. when building a large package)
    # if this, somehow, doesn't meet your requirements you may just bump the numbers up
    loginLimits = [
      {
        domain = "@wheel";
        item = "nofile";
        type = "soft";
        value = "524288";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "1048576";
      }
    ];

    services = let
      ttyAudit = {
        enable = true;
        enablePattern = "*";
      };
      fprintAuth = config.services.fprintd.enable;
      enableGnomeKeyring = mkDefault config.my.desktop.enable;
      gnupg = {
        enable = true;
        noAutostart = true;
        storeOnly = true;
      };
      privilegeEscalationServices =
        if sudoCfg.backend == "doas"
        then {
          doas = {
            inherit ttyAudit;
            setLoginUid = true;
          };
        }
        else {
          sudo = {
            inherit ttyAudit;
            setLoginUid = true;
          };
          sudo-i = {
            inherit ttyAudit;
            setLoginUid = true;
          };
        };
    in
      {
        # Allow screen lockers such as Swaylock or gtklock) to also unlock the screen.
        swaylock.text = pamInclude;
        gtklock.text = pamInclude;
        hyprlock.text = pamInclude;
        greetd.text = pamInclude;
        tuigreet.text = pamInclude;

        login = {
          inherit
            ttyAudit
            fprintAuth
            gnupg
            enableGnomeKeyring
            ;
          setLoginUid = true;
        };

        sshd = {
          inherit ttyAudit;
          setLoginUid = true;
        };
      }
      // privilegeEscalationServices;
  };
}
