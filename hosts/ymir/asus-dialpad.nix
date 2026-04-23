{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  inherit (lib.modules) mkForce;

  inherit (pkgs.stdenv.hostPlatform) system;
  stateDir = "/var/lib/asus-dialpad-driver";

  basePackage = inputs.asus-dialpad-driver.packages.${system}.default.override {
    waylandSupport = true;
  };

  patchedPackage = basePackage.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace dialpad.py \
        --replace-fail 'coactivator_keys = None' 'coactivator_keys = []'
      substituteInPlace dialpad.py \
        --replace-fail 'global udev, dev, modifiers' 'global udev, dev, modifiers, uinput_device' \
        --replace-fail 'udev = dev.create_uinput_device()' 'uinput_device = udev = dev.create_uinput_device()'
    '';
  });

  seedConfig = pkgs.writeText "asus-dialpad-driver-dialpad_dev" ''
    [main]
    enabled = 1
    socket_enabled = 0
    disable_due_inactivity_time = 0
    touchpad_disables_dialpad = 1
    activation_time = 1.0
    config_supress_app_specifics_shortcuts = 0
    top_right_icon_coactivator_key =
    socket_send_progress_above_treshold = 120
  '';

  startDriver = pkgs.writeShellApplication {
    name = "asus-dialpad-driver-start";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      install -d -m 0755 ${stateDir}
      if [ ! -s ${stateDir}/dialpad_dev ]; then
        cp ${seedConfig} ${stateDir}/dialpad_dev
        chmod 0644 ${stateDir}/dialpad_dev
      fi

      exec ${patchedPackage}/share/asus-dialpad-driver/dialpad.py ${config.services.asus-dialpad-driver.layout} ${stateDir}/
    '';
  };
in
{
  imports = [
    inputs.asus-dialpad-driver.nixosModules.default
  ];

  services.asus-dialpad-driver = {
    enable = true;
    package = patchedPackage;
    layout = "proartp16";
    wayland = true;
    runtimeDir = "/run/user/1000/";
    # This runs as a system service, so it needs the session socket pinned explicitly.
    waylandDisplay = "wayland-1";
  };

  systemd.services.asus-dialpad-driver.serviceConfig = {
    ExecStart = mkForce (getExe startDriver);
    StateDirectory = "asus-dialpad-driver";
    WorkingDirectory = mkForce "${patchedPackage}/share/asus-dialpad-driver";
  };
}
