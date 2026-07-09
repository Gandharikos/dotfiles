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
      github-copilot-cli
      qwen-code
    ]
    ++ optionals hermesEnabled [
      hermes-hud
    ];
}
