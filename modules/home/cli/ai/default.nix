{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.dot.scanPaths ./.;
  home.packages = with pkgs.llm-agents; [
    copilot-cli
    cursor-agent
    qwen-code
  ];
}
