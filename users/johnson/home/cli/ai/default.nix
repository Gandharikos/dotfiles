{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.lists) optionals;
  hermesEnabled = osConfig.dot.services.hermes-agent.enable or false;
in
{
  imports = lib.dot.scanPaths ./.;

  home.packages =
    with pkgs;
    [
      cursor-agent
      dot.zaly
    ]
    ++ optionals hermesEnabled [
      hermes-hud
    ];
}
