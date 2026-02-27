{
  lib,
  pkgs,
  ...
}: {
  imports = lib.my.scanPaths ./.;
  home.packages = with pkgs.llm-agents; [
    copilot-cli
    cursor-agent
    qwen-code
  ];
}
