{
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.zed;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.zed = {
    enable = mkEnableOption "Zed" // {
      default = true;
    };
  };

  config = mkIf enable {
    programs.zed-editor = {
      enable = true;
      mutableUserSettings = true;

      userSettings = {
        agent.play_sound_when_agent_done = "when_hidden";
        agent_buffer_font_size = lib.mkDefault 17.0;
        agent_servers = {
          claude-acp.type = "registry";
          codex-acp.type = "registry";
          cursor.type = "registry";
          opencode.type = "registry";
        };
        agent_ui_font_size = lib.mkDefault 18.0;
        auto_signature_help = true;
        auto_update = false;
        autosave = "on_focus_change";
        buffer_font_family = lib.mkDefault "Maple Mono NF CN";
        buffer_font_size = lib.mkDefault 16.0;
        centered_layout = {
          left_padding = 0.15;
          right_padding = 0.15;
        };
        chat_panel.dock = "right";
        cli_default_open_behavior = "existing_window";
        code_lens = "on";
        collaboration_panel = {
          button = false;
          dock = "left";
        };
        completion_menu_item_kind = "symbol";
        completions.lsp_fetch_timeout_ms = 2000;
        diagnostics.inline.enabled = true;
        document_folding_ranges = "off";
        edit_predictions = {
          allow_data_collection = "no";
          disabled_globs = [
            "**/.git"
            "**/.svn"
            "**/.hg"
            "**/CVS"
            "**/.DS_Store"
            "**/Thumbs.db"
            "**/.classpath"
            "**/.settings"
            "**/.vscode"
            "**/.idea"
            "**/node_modules"
            "**/.serverless"
            "**/build"
            "**/dist"
            "**/coverage"
            "**/.venv"
            "**/__pycache__"
            "**/.ropeproject"
            "**/.pytest_cache"
            "**/.ruff_cache"
          ];
          enabled_in_assistant = false;
          mode = "eager";
        };
        file_scan_exclusions = [
          "**/.git"
          "**/.svn"
          "**/.hg"
          "**/CVS"
          "**/.DS_Store"
          "**/Thumbs.db"
          "**/.classpath"
          "**/.settings"
          "**/.vscode"
          "**/.idea"
          "**/node_modules"
          "**/.serverless"
          "**/build"
          "**/dist"
          "**/coverage"
          "**/.venv"
          "**/__pycache__"
          "**/.ropeproject"
          "**/.pytest_cache"
          "**/.ruff_cache"
        ];
        file_scan_inclusions = [ ".env" ];
        file_types = {
          Dockerfile = [
            "Dockerfile"
            "Dockerfile.*"
          ];
          JSON = [
            "json"
            "jsonc"
            "*.code-snippets"
          ];
        };
        git.inline_blame.show_commit_summary = true;
        helix_mode = false;
        indent_guides = {
          background_coloring = "indent_aware";
          enabled = true;
          coloring = "indent_aware";
        };
        inlay_hints.enabled = true;
        minimap.show = "auto";
        notification_panel = {
          button = false;
          enabled = false;
        };
        outline_panel = {
          button = false;
          dock = "right";
        };
        prettier.allowed = true;
        preferred_line_length = 120;
        project_panel = {
          button = false;
          default_width = 300;
          dock = "left";
          file_icons = true;
          folder_icons = true;
          git_status = true;
          scrollbar.show = "never";
        };
        projects_online_by_default = false;
        relative_line_numbers = "enabled";
        scrollbar.show = "never";
        search.regex = true;
        semantic_tokens = "combined";
        soft_wrap = "editor_width";
        tab_bar = {
          show = true;
          show_nav_history_buttons = false;
        };
        tabs = {
          file_icons = true;
          git_status = true;
        };
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        terminal = {
          button = false;
          detect_venv.on = {
            activate_script = "default";
            directories = [
              ".venv"
              "venv"
            ];
          };
          env = {
            EDITOR = "zed --wait";
            ZED_TERMINAL = "1";
          };
        };
        title_bar = {
          show_branch_status_icon = true;
          show_menus = false;
          show_user_menu = true;
        };
        toolbar = {
          quick_actions = false;
          title = false;
        };
        ui_font_family = lib.mkDefault "LXGW WenKai Screen";
        ui_font_size = lib.mkDefault 18.0;
        use_smartcase_search = true;
        vertical_scroll_margin = 5.0;
        vim_mode = true;
        vim = {
          toggle_relative_line_numbers = true;
          use_smartcase_find = true;
        };
        which_key = {
          enabled = true;
          delay_ms = 0;
        };
      };

      userKeymaps = [
        {
          context = "Workspace";
          bindings = {
            "ctrl-/" = "terminal_panel::Toggle";
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-q" = "workspace::CloseWindow";
          };
        }
        {
          context = "Editor";
          bindings = {
            "ctrl-/" = "terminal_panel::Toggle";
            "ctrl-q" = "workspace::CloseWindow";
          };
        }
        {
          context = "Terminal";
          bindings = {
            "ctrl-/" = "terminal_panel::Toggle";
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-q" = "workspace::CloseWindow";
          };
        }
        {
          context = "Editor && (vim_mode == normal || vim_mode == helix_normal || vim_mode == helix_select) && !menu";
          bindings = {
            "alt-h" = "vim::ResizePaneLeft";
            "alt-j" = "vim::ResizePaneDown";
            "alt-k" = "vim::ResizePaneUp";
            "alt-l" = "vim::ResizePaneRight";
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "down" = "editor::MoveLineDown";
            "enter" = "vim::HelixJumpToWord";
            "left" = "editor::Outdent";
            "right" = "editor::Indent";
            "shift-h" = "pane::ActivatePreviousItem";
            "shift-l" = "pane::ActivateNextItem";
            "space space" = "file_finder::Toggle";
            "space /" = "pane::DeploySearch";
            "space e" = "pane::RevealInProjectPanel";
            "space ," = "tab_switcher::ToggleAll";
            "space f f" = "file_finder::Toggle";
            "space f n" = "workspace::NewFile";
            "space f r" = [
              "projects::OpenRecent"
              {
                create_new_window = false;
              }
            ];
            "space f s" = "workspace::Save";
            "space f a" = "workspace::SaveAll";
            "space b b" = "tab_switcher::ToggleAll";
            "space b d" = [
              "pane::CloseActiveItem"
              {
                close_pinned = false;
              }
            ];
            "space b o" = [
              "pane::CloseOtherItems"
              {
                close_pinned = false;
              }
            ];
            "space b n" = "pane::ActivateNextItem";
            "space b p" = "pane::ActivatePreviousItem";
            "space c a" = "editor::ToggleCodeActions";
            "space c f" = "editor::Format";
            "space c o" = "editor::OrganizeImports";
            "space c r" = "editor::Rename";
            "space g b" = "git::Blame";
            "space g d" = "git::Diff";
            "space g g" = [
              "task::Spawn"
              {
                task_name = "lazygit";
                reveal_target = "center";
              }
            ];
            "space g l" = "editor::BlameHover";
            "space g s" = "git_panel::ToggleFocus";
            "space s b" = "buffer_search::Deploy";
            "space s d" = "diagnostics::Deploy";
            "space s g" = "pane::DeploySearch";
            "space s p" = "project_symbols::Toggle";
            "space s s" = "outline::Toggle";
            "space u h" = "editor::ToggleInlayHints";
            "space u w" = "editor::ToggleSoftWrap";
            "space w h" = "workspace::ActivatePaneLeft";
            "space w j" = "workspace::ActivatePaneDown";
            "space w k" = "workspace::ActivatePaneUp";
            "space w l" = "workspace::ActivatePaneRight";
            "space w o" = "pane::JoinAll";
            "space w q" = [
              "pane::CloseActiveItem"
              {
                close_pinned = false;
              }
            ];
            "space w s" = "pane::SplitDown";
            "space w v" = "pane::SplitRight";
            "space w z" = "workspace::ToggleZoom";
            "space x x" = "diagnostics::Deploy";
            "s h" = "pane::SplitLeft";
            "s j" = "pane::SplitDown";
            "s k" = "pane::SplitUp";
            "s l" = "pane::SplitRight";
            "s o" = [
              "action::Sequence"
              [
                "vim::InsertLineBelow"
                "vim::SwitchToNormalMode"
              ]
            ];
            "s shift-h" = "workspace::MovePaneLeft";
            "s shift-j" = "workspace::MovePaneDown";
            "s shift-k" = "workspace::MovePaneUp";
            "s shift-l" = "workspace::MovePaneRight";
            "s shift-o" = [
              "action::Sequence"
              [
                "vim::InsertLineAbove"
                "vim::SwitchToNormalMode"
              ]
            ];
            "up" = "editor::MoveLineUp";
          };
        }
        {
          context = "(vim_mode == normal || vim_mode == helix_normal) && !menu";
          bindings = {
            "g c c" = [
              "action::Sequence"
              [
                "vim::PushToggleComments"
                "vim::CurrentLine"
              ]
            ];
            "g c o" = [
              "action::Sequence"
              [
                "vim::InsertLineBelow"
                "vim::SwitchToNormalMode"
                "vim::PushToggleComments"
                "vim::CurrentLine"
                "vim::InsertEndOfLine"
              ]
            ];
            "g c shift-o" = [
              "action::Sequence"
              [
                "vim::InsertLineAbove"
                "vim::SwitchToNormalMode"
                "vim::PushToggleComments"
                "vim::CurrentLine"
                "vim::InsertEndOfLine"
              ]
            ];
          };
        }
        {
          context = "vim_mode == visual";
          bindings = {
            "down" = "editor::MoveLineDown";
            "left" = "editor::Outdent";
            "right" = "editor::Indent";
            "shift-j" = "editor::MoveLineDown";
            "shift-k" = "editor::MoveLineUp";
            "up" = "editor::MoveLineUp";
          };
        }
        {
          context = "ProjectPanel && not_editing";
          bindings = {
            "a" = "project_panel::NewFile";
            "shift-a" = "project_panel::NewDirectory";
            "r" = "project_panel::Rename";
            "d" = "project_panel::Delete";
            "x" = "project_panel::Cut";
            "c" = "project_panel::Copy";
            "p" = "project_panel::Paste";
            "/" = "project_panel::NewSearchInDirectory";
            "escape" = "project_panel::Toggle";
            "q" = "project_panel::Toggle";
            "space e" = null;
          };
        }
        {
          context = "!Editor && !Terminal";
          bindings."space e" = null;
        }
      ];

      userTasks = [
        {
          label = "lazygit";
          command = "lazygit";
          use_new_terminal = true;
          reveal_target = "center";
          hide = "never";
        }
      ];

      extensions = [
        "dockerfile"
        "just"
        "nix"
        "nu"
        "terraform"
        "toml"
      ];
    };
  };
}
