{ lib, pkgs, ... }:
{
  dot = {
    primaryUser = "johnson";

    users.johnson = {
      shell = lib.mkForce "bash";
      home.my = {
        atuin.enable = lib.mkForce false;
        starship.enable = lib.mkForce false;
      };
    };

    device = {
      type = "vm";
      cpu = "vm-intel";
    };

    kernel.packages = pkgs.linuxPackages;

    virtual.podman.enable = true;

    services.zfs.enable = true;
  };

  users.users.johnson.autoSubUidGidRange = true;

  services.userborn.enable = lib.mkForce false;

  security.account-utils.enable = lib.mkForce false;

  boot.kernel.sysctl = {
    # This VM is intentionally permissive for eBPF learning and tracing.
    "kernel.ftrace_enabled" = lib.mkForce true;
    "kernel.kptr_restrict" = lib.mkForce 0;
    "kernel.perf_event_paranoid" = lib.mkForce 1;
    "kernel.unprivileged_bpf_disabled" = lib.mkForce false;
    "net.core.bpf_jit_enable" = lib.mkForce true;
    "net.core.bpf_jit_harden" = lib.mkForce 0;
  };

  system = {
    nixos-init.enable = lib.mkForce false;
    etc.overlay.enable = lib.mkForce false;
  };

  environment = {
    systemPackages = with pkgs; [
      bpftools
      bpftrace
      clang
      elfutils
      gcc
      gnumake
      libbpf
      llvmPackages.clang-tools
      perf
      pkg-config
      zlib
    ];

    etc."mimir/index.html".text = ''
      mimir: ok
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  systemd.tmpfiles.settings.mimir = {
    "/var/lib/mimir".d = {
      user = "root";
      group = "root";
      mode = "0750";
    };
    "/var/lib/mimir/uptime-kuma".d = {
      user = "root";
      group = "root";
      mode = "0750";
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."mimir.local" = {
      default = true;
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:3001";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_read_timeout 300s;
          '';
        };
        "/healthz" = {
          return = "200 'mimir: healthy\n'";
          extraConfig = ''
            add_header Content-Type text/plain;
          '';
        };
      };
    };
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.uptime-kuma = {
      image = "docker.io/louislam/uptime-kuma:1";
      autoStart = true;
      ports = [ "127.0.0.1:3001:3001" ];
      volumes = [ "/var/lib/mimir/uptime-kuma:/app/data" ];
      extraOptions = [ "--security-opt=no-new-privileges" ];
    };
  };

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 2;
      memorySize = 2048;
      diskSize = 8192;
      emptyDiskImages = [ 4096 ];
      graphics = false;
      forwardPorts = [
        {
          from = "host";
          host.port = 8080;
          guest.port = 80;
        }
        {
          from = "host";
          host.port = 10022;
          guest.port = 22;
        }
      ];
    };
  };

  system.stateVersion = "26.11";
}
