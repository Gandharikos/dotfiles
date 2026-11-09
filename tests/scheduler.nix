# Evaluation only: never starts or switches a scheduler.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  check =
    deviceType: enabled:
    let
      host = flake.nixosConfigurations.ymir.extendModules {
        modules = [ { dot.device.type = lib.mkForce deviceType; } ];
      };
      inherit (host) config pkgs;
      loader = config.services.scx-loader;
    in
    assert builtins.all (entry: entry.assertion) config.assertions;
    assert loader.enable == enabled;
    assert config.boot.kernel.sysctl."net.core.bpf_jit_enable" == enabled;
    assert loader.config.default_sched == "scx_bpfland";
    assert loader.schedsPackages == [ pkgs.scx.rustscheds ];
    assert !(builtins.hasAttr "scx" config.systemd.services);
    assert builtins.hasAttr "scx_loader" config.systemd.services == enabled;
    assert enabled -> builtins.elem "multi-user.target" config.systemd.services.scx_loader.wantedBy;
    true;
in
{
  workstation = check "workstation" true;
  server = check "server" false;
  desktop = check "desktop" false;
  laptop = check "laptop" false;
}
