# Mimir DevOps Lab TODO

`mimir` is the local NixOS VM for practicing deployment, service operations, and infrastructure
debugging before touching real machines.

## 1. VM Basics

- [x] Start the VM.

  ```bash
  just vm
  ```

- [x] Verify host-to-VM port forwarding.

  ```bash
  curl http://127.0.0.1:8080/healthz
  ssh -p 10022 johnson@127.0.0.1
  ```

- [x] Check the system state inside the VM.

  ```bash
  systemctl --failed
  systemctl status nginx
  journalctl -u nginx -n 100 --no-pager
  ```

## 2. NixOS Service Workflow

- [x] Change the `/healthz` response in `hosts/mimir/config.nix`.
- [x] Rebuild and restart the VM.

  ```bash
  nix build path:/home/johnson/.dotfiles#nixosConfigurations.mimir.config.system.build.vm
  just vm
  ```

- [x] Confirm the new response.

  ```bash
  curl http://127.0.0.1:8080/healthz
  ```

- [x] Break the nginx config on purpose, rebuild, read the error, then fix it.

## 3. Custom Systemd Service

- [ ] Add a small `mimir-agent` service that listens on `127.0.0.1:9000`.
- [ ] Make it return JSON like:

  ```json
  { "status": "ok", "host": "mimir" }
  ```

- [ ] Manage it with systemd.

  ```bash
  systemctl status mimir-agent
  journalctl -u mimir-agent -f
  ```

- [ ] Add an nginx route that proxies `/api/healthz` to `mimir-agent`.
- [ ] Verify from the host.

  ```bash
  curl http://127.0.0.1:8080/api/healthz
  ```

## 4. Failure And Recovery

- [ ] Stop nginx and observe the failed health check.

  ```bash
  sudo systemctl stop nginx
  curl http://127.0.0.1:8080/healthz
  ```

- [ ] Restart nginx and confirm recovery.

  ```bash
  sudo systemctl restart nginx
  systemctl status nginx
  ```

- [ ] Inspect logs for the failure window.

  ```bash
  journalctl -u nginx --since "10 minutes ago"
  ```

## 5. Podman Basics

- [x] Enable Podman for `mimir`.
- [x] Run a simple container inside the VM.

  ```bash
  podman run --rm hello-world
  ```

- [x] Run an HTTP container on an internal port.
- [x] Manage the container with systemd instead of a manual shell command.
- [x] Reverse proxy the container through nginx.

## 6. Persistent Data

- [ ] Add a VM data directory for a service.
- [ ] Mount it into a Podman container.
- [ ] Delete and recreate the container without losing data.
- [ ] Check ownership and permissions.

## 7. Storage Practice

- [ ] Add a second virtual disk to `mimir`.
- [ ] Create a test filesystem or ZFS pool on it.
- [ ] Practice:

  ```bash
  zpool status
  zfs snapshot
  zfs rollback
  zpool scrub
  ```

- [ ] Document what survives VM rebuilds and what does not.

## 8. Observability

- [ ] Add a basic service health check.
- [ ] Export simple metrics, or install node exporter.
- [ ] Check CPU, memory, disk, and service status.
- [ ] Create a short runbook for debugging a failed service.

## 9. Deployment Thinking

- [ ] Write down the exact deployment flow for `mimir`:

  ```text
  edit -> format -> build -> boot VM -> health check -> inspect logs
  ```

- [ ] Compare this with `just deploy <host>` for real machines.
- [ ] Identify which steps are missing before this could be production-like.

## 10. Kubernetes Prep

- [ ] Explain the difference between:

  ```text
  systemd service
  Podman container
  Kubernetes Pod
  Kubernetes Deployment
  Kubernetes StatefulSet
  ```

- [ ] Only after the Podman and storage exercises are comfortable, install k3s in a separate VM or a
      later `mimir` iteration.
