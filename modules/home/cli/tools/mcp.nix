{
  config,
  lib,
  # pkgs,
  inputs,
  system,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkDefault;
  inherit (lib.meta) getExe hasAttrByPath;
  inherit (lib.attrsets) optionalAttrs;

  cfg = config.my.mcp;
  mcpPkgs = inputs.mcp-servers-nix.packages.${system};
  hasTavilyApiKey = hasAttrByPath [ "sops" "secrets" "tavily_api_key" ] config;
in
{
  options.my.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) servers";
  };

  config = mkIf cfg.enable {
    sops.secrets.github_token = { };
    programs.mcp = {
      # MCP documentation
      # See: https://modelcontextprotocol.io/
      enable = true;
      servers = {
        fetch = {
          command = getExe mcpPkgs.mcp-server-fetch;
        };

        filesystem = {
          command = getExe mcpPkgs.mcp-server-filesystem;
          args = mkDefault [
            config.home.homeDirectory
            "${config.home.homeDirectory}/Documents"
            "${config.home.homeDirectory}/.dotfiles"
            "/nix/store"
          ];
        };

        sequential-thinking = {
          command = getExe mcpPkgs.mcp-server-sequential-thinking;
        };

        git = {
          command = getExe mcpPkgs.mcp-server-git;
        };

        tavily = {
          command = getExe mcpPkgs.tavily-mcp;
        }
        // optionalAttrs hasTavilyApiKey {
          env = {
            # Handled by development suite via shell exports, but good to be explicit
            TAVILY_API_KEY = "$(cat ${config.sops.secrets.tavily_api_key.path})";
          };
        };

        # FIXME: broken nixpkgs
        # nixos = {
        #   command = getExe pkgs.mcp-nixos;
        # };
      };
    };
  };
}
