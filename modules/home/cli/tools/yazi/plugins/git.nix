{ pkgs, ... }:
{
  # Show the status of GIt file changes as linemode in the file list
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) git; };
    initLua = ''
      require("git"):setup()

      -- https://github.com/yazi-rs/plugins/tree/main/git.yazi
      th.git = th.git or {}

      th.git.added = ui.Style():fg("blue")
      th.git.added_sign = ""

      th.git.deleted = ui.Style():fg("red"):bold()
      th.git.deleted_sign = ""

      th.git.ignored = ui.Style():fg("gray")
      th.git.ignored_sign = ""

      th.git.modified = ui.Style():fg("green")
      th.git.modified_sign = ""

      th.git.untracked = ui.Style():fg("gray")
      th.git.untracked_sign = ""

      th.git.updated = ui.Style():fg("green")
      th.git.updated_sign = ""
    '';

    settings.plugin.prepend_fetchers = [
      {
        id = "git";
        name = "*";
        run = "git";
      }
      {
        id = "git";
        name = "*/";
        run = "git";
      }
    ];
  };
}
