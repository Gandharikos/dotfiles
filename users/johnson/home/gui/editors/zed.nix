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
        which_key.enabled = true;
      };

      extensions = [
        "catppuccin"
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
