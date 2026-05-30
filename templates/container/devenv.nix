{ pkgs, ... }:

{
  packages = [
    pkgs.dive
    pkgs.docker-compose
    pkgs.podman
    pkgs.skopeo
  ];
}
