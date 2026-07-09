{
  config,
  lib,
  pkgs,
  aiCommon,
  ...
}:
let
  inherit (config.my) name;
  cfg = config.my.github-copilot-cli;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  mcpModuleEnabled = config.my.mcp.enable or false;
in
{
  options.my.github-copilot-cli.enable = mkEnableOption "GitHub Copilot CLI";

  config = mkIf cfg.enable {
    programs.github-copilot-cli = {
      enable = true;
      enableMcpIntegration = mcpModuleEnabled;

      inherit (aiCommon.githubCopilotCli) context agents skills;
      settings = {
        model = "gpt-5.5";
        effortLevel = "high";
        theme = "default";
        banner = "once";
        autoUpdate = false;
        renderMarkdown = true;
        includeCoAuthoredBy = false;
        respectGitignore = true;
        enabledFeatureFlags = {
          QUEUED_COMMANDS = true;
        };
      };
      lspServers = {
        nixd = {
          command = lib.getExe pkgs.nixd;
          fileExtensions = {
            ".nix" = "nix";
          };
          initializationOptions = {
            formatting.command = [ (lib.getExe pkgs.nixfmt) ];
          };
        };

        emmylua-ls = {
          command = lib.getExe pkgs.emmylua-ls;
          fileExtensions = {
            ".lua" = "lua";
          };
          initializationOptions.Lua = {
            diagnostics.globals = [
              "vim"
              "Sbar"
              "spoon"
            ];
            workspace.library = [
              "/etc/profiles/per-user/${name}/share/lua/5.1"
            ];
          };
        };

        basedpyright = {
          command = lib.getExe' pkgs.basedpyright "basedpyright-langserver";
          args = [ "--stdio" ];
          fileExtensions = {
            ".py" = "python";
            ".pyi" = "python";
            ".pyw" = "python";
          };
        };

        bashls = {
          command = lib.getExe pkgs.bash-language-server;
          args = [ "start" ];
          fileExtensions = {
            ".bash" = "shellscript";
            ".sh" = "shellscript";
          };
        };

        clangd = {
          command = lib.getExe' pkgs.clang-tools "clangd";
          fileExtensions = {
            ".c" = "c";
            ".c++" = "cpp";
            ".cc" = "cpp";
            ".cpp" = "cpp";
            ".cxx" = "cpp";
            ".h" = "c";
            ".h++" = "cpp";
            ".hh" = "cpp";
            ".hpp" = "cpp";
            ".hxx" = "cpp";
          };
        };

        fish-lsp = {
          command = lib.getExe pkgs.fish-lsp;
          fileExtensions = {
            ".fish" = "fish";
          };
        };

        typescript = {
          command = lib.getExe pkgs.typescript-language-server;
          args = [ "--stdio" ];
          fileExtensions = {
            ".cjs" = "javascript";
            ".cts" = "typescript";
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
            ".mjs" = "javascript";
            ".mts" = "typescript";
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
          };
        };

        gopls = {
          command = lib.getExe pkgs.gopls;
          fileExtensions = {
            ".go" = "go";
            ".mod" = "gomod";
            ".sum" = "gosum";
          };
        };

        rust-analyzer = {
          command = lib.getExe pkgs.rust-analyzer;
          fileExtensions = {
            ".rs" = "rust";
          };
        };

        marksman = {
          command = lib.getExe pkgs.marksman;
          fileExtensions = {
            ".md" = "markdown";
            ".mdx" = "mdx";
          };
        };

        yamlls = {
          command = lib.getExe pkgs.yaml-language-server;
          args = [ "--stdio" ];
          fileExtensions = {
            ".yaml" = "yaml";
            ".yml" = "yaml";
          };
        };

        jsonls = {
          command = lib.getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server";
          args = [ "--stdio" ];
          fileExtensions = {
            ".json" = "json";
            ".jsonc" = "jsonc";
          };
        };

        taplo = {
          command = lib.getExe pkgs.taplo;
          args = [
            "lsp"
            "stdio"
          ];
          fileExtensions = {
            ".toml" = "toml";
          };
        };
      };
    };

    programs.gh.extensions = [
      pkgs.github-copilot-cli
    ];
  };
}
