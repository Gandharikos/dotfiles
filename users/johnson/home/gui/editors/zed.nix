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
        agent_buffer_font_size = lib.mkDefault 15.0;
        agent_servers = {
          claude-acp.type = "registry";
          codex-acp.type = "registry";
          cursor.type = "registry";
          opencode.type = "registry";
        };
        agent_ui_font_size = lib.mkDefault 16.0;
        auto_signature_help = true;
        auto_update = false;
        autosave = "on_focus_change";
        buffer_font_family = lib.mkDefault "Maple Mono NF CN";
        buffer_font_size = lib.mkDefault 14.0;
        cli_default_open_behavior = "existing_window";
        code_lens = "on";
        completion_menu_item_kind = "symbol";
        completions.lsp_fetch_timeout_ms = 2000;
        diagnostics.inline.enabled = true;
        document_folding_ranges = "off";
        edit_predictions.allow_data_collection = "no";
        git.inline_blame.show_commit_summary = true;
        helix_mode = true;
        indent_guides = {
          background_coloring = "indent_aware";
          coloring = "indent_aware";
        };
        inlay_hints.enabled = true;
        minimap.show = "auto";
        prettier.allowed = true;
        project_panel.dock = "left";
        relative_line_numbers = "enabled";
        search.regex = true;
        semantic_tokens = "combined";
        soft_wrap = "editor_width";
        tabs = {
          file_icons = true;
          git_status = true;
        };
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        terminal.env.ZED_TERMINAL = "1";
        title_bar = {
          show_branch_status_icon = true;
          show_menus = false;
          show_user_menu = true;
        };
        ui_font_family = lib.mkDefault "LXGW WenKai Screen";
        ui_font_size = lib.mkDefault 16.0;
        use_smartcase_search = true;
        vertical_scroll_margin = 5.0;
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
          bindings."ctrl-/" = "terminal_panel::Toggle";
        }
        {
          context = "Editor";
          bindings."ctrl-/" = "terminal_panel::Toggle";
        }
        {
          context = "Terminal";
          bindings."ctrl-/" = "terminal_panel::Toggle";
        }
        {
          context = "Editor && (vim_mode == normal || vim_mode == helix_normal || vim_mode == helix_select) && !menu";
          bindings = {
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-l" = "workspace::ActivatePaneRight";
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
            "shift-j" = "editor::MoveLineDown";
            "shift-k" = "editor::MoveLineUp";
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
            "q" = "project_panel::ToggleFocus";
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
