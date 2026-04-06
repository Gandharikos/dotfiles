{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe getExe';
  inherit (lib.lists) optionals;
  inherit (lib.strings) concatStringsSep escapeShellArgs;

  cfg = config.my.networking.tailscale;
  isClient = cfg.role == "client";
  isSubnetRouter = builtins.elem cfg.role [
    "subnet-router"
    "router-exit-node"
  ];
  isExitNode = builtins.elem cfg.role [
    "exit-node"
    "router-exit-node"
  ];
  isRoutingServer = isSubnetRouter || isExitNode;
  advertiseRoutesFlag = optionals (isSubnetRouter && cfg.advertiseRoutes != [ ]) [
    "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}"
  ];

  stateDir = "/var/lib/tailscale";
  socketPath = "/var/run/tailscaled.socket";
  tailscale' = getExe pkgs.tailscale;
  tailscaled' = getExe' pkgs.tailscale "tailscaled";
  upArgs =
    cfg.defaultFlags
    ++ optionals isClient [
      "--accept-routes"
    ]
    ++ optionals isExitNode [
      "--advertise-exit-node"
    ]
    ++ advertiseRoutesFlag
    ++ optionals isRoutingServer [
      "--operator=${config.my.name}"
    ]
    ++ optionals cfg.autoConnect [
      "--auth-key=file:${config.sops.secrets.tailscale_authKey.path}"
    ];
  tailscaleUp = pkgs.writeShellApplication {
    name = "tailscale-up";
    runtimeInputs = [ pkgs.tailscale ];
    text = ''
      attempts=0
      while [ ! -r ${config.sops.secrets.tailscale_authKey.path} ]; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 30 ]; then
          echo "tailscale auth key did not appear in time" >&2
          exit 1
        fi
        sleep 1
      done

      attempts=0
      while [ ! -S ${socketPath} ]; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 30 ]; then
          echo "tailscaled socket did not appear in time" >&2
          exit 1
        fi
        sleep 1
      done

      exec ${tailscale'} up --reset --timeout=30s ${escapeShellArgs upArgs}
    '';
  };
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    sops.secrets = mkIf cfg.autoConnect {
      tailscale_authKey = {
        owner = "root";
        group = "wheel";
        mode = "0400";
      };
    };

    launchd.daemons.tailscaled = {
      serviceConfig = {
        ProgramArguments = [
          tailscaled'
          "--statedir=${stateDir}"
          "--socket=${socketPath}"
          "--no-logs-no-support"
        ];
        Label = "org.nixos.tailscaled";
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/log/tailscaled.log";
        StandardErrorPath = "/var/log/tailscaled-error.log";
        WorkingDirectory = "/tmp";
      };
    };

    launchd.daemons.tailscale-up = mkIf cfg.autoConnect {
      serviceConfig = {
        ProgramArguments = [ (getExe tailscaleUp) ];
        Label = "org.nixos.tailscale-up";
        RunAtLoad = true;
        StandardOutPath = "/var/log/tailscale-up.log";
        StandardErrorPath = "/var/log/tailscale-up-error.log";
        WorkingDirectory = "/tmp";
      };
    };

    system.activationScripts.tailscale-setup.text = ''
      mkdir -p ${stateDir}
      chown root:wheel ${stateDir}
      chmod 0700 ${stateDir}
    '';

    assertions = [
      {
        assertion = !isSubnetRouter || cfg.advertiseRoutes != [ ];
        message = "Tailscale roles `subnet-router` and `router-exit-node` require `my.networking.tailscale.advertiseRoutes` to be non-empty.";
      }
    ];
  };
}
