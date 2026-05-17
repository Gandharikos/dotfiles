{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.jujutsu;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.jujutsu = {
    enable = mkEnableOption "jujutsu";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      lazyjj
    ];

    programs.jujutsu = {
      enable = true;
      settings = {
        fetch.prune = true;
        init.default_branch = "main";
        push = {
          autoSetupRemote = true;
          default = "current";
        };
        rebase.auto_stash = true;
        lfs = true;
        aliases = {
          ld = [
            "log"
            "--template"
            "log_detailed"
          ];
          ls = [
            "log"
            "--template"
            "log_stat"
          ];
        };
        colors = {
          "diff removed token" = {
            underline = false;
          };
          "diff added token" = {
            underline = false;
          };
        };
        git.subprocess = true;
        # https://martinvonz.github.io/jj/latest/templates/
        # https://github.com/martinvonz/jj/blob/main/cli/src/config/templates.toml
        template-aliases = {
          description_placeholder = ''label("description placeholder", "(no description)")'';
          log_custom = ''
            if(root,
              format_root_commit(self),
              label(if(current_working_copy, "working_copy"),
                concat(
                  format_short_commit_header(self) ++ "\n",
                  separate(" ",
                    if(empty, label("empty", "(empty)")),
                    if(description,
                      description.first_line(),
                      if(empty, label("empty", description_placeholder), diff.summary()),
                    ),
                  ),
                ),
              )
            )
          '';
          log_detailed = ''concat(builtin_log_detailed, diff.stat(120), "\n")'';
          log_stat = "concat(builtin_log_compact, diff.summary())";
        };
        templates = {
          log = "log_custom";
        };
        ui = {
          default-command = "log";
          diff-editor = [
            "nvim"
            "-c"
            "DiffEditor $left $right $output"
          ];
          diff-instructions = false;
          diff-formatter = "git";
        };
        user = {
          inherit (config.my) email name;
        };
      };
    };
  };
}
