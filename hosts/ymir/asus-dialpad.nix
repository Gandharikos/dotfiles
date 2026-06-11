{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  inherit (lib.modules) mkAfter mkForce;

  inherit (pkgs.stdenv.hostPlatform) system;

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
      config_dir="''${1:?config directory required}"

      install -d -m 0700 "$config_dir"
      if [ ! -s "$config_dir/dialpad_dev" ]; then
        cp ${seedConfig} "$config_dir/dialpad_dev"
        chmod 0644 "$config_dir/dialpad_dev"
      fi

      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      exec ${patchedPackage}/share/asus-dialpad-driver/dialpad.py ${config.hardware.asus-dialpad-driver.layout} "$config_dir/"
    '';
  };
in
{
  imports = [
    inputs.asus-dialpad-driver.nixosModules.default
  ];

  hardware.asus-dialpad-driver = {
    enable = true;
    package = patchedPackage;
    layout = "proartp16";
    sessionTypes = [ "wayland" ];
  };

  users.users.${config.dot.primaryUser}.extraGroups = mkAfter [
    "i2c"
    "input"
    "uinput"
  ];

  systemd.user.services.asus-dialpad-driver.serviceConfig = {
    ExecStart = mkForce "${getExe startDriver} %E/asus-dialpad-driver";
    Environment = mkForce [
      "LOG=INFO"
      "XDG_SESSION_TYPE=wayland"
      "WAYLAND_DISPLAY=wayland-1"
    ];
    WorkingDirectory = mkForce "${patchedPackage}/share/asus-dialpad-driver";
  };
}
