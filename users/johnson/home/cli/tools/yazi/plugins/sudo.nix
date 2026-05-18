{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) sudo; };
    keymap = {
      mgr.append_keymap = [
        {
          on = [
            "R"
            "p"
            "p"
          ];
          run = "plugin sudo -- paste";
          desc = "sudo paste";
        }
        {
          # sudo cp/mv --force
          on = [
            "R"
            "P"
          ];
          run = "plugin sudo -- paste --force";
          desc = "sudo paste";
        }
        {
          # sudo mv
          on = [
            "R"
            "r"
          ];
          run = "plugin sudo -- rename";
          desc = "sudo rename";
        }
        {
          # sudo ln -s (absolute-path)
          on = [
            "R"
            "p"
            "l"
          ];
          run = "plugin sudo -- link";
          desc = "sudo link";
        }
        {
          # sudo ln -s (relative-path)
          on = [
            "R"
            "p"
            "r"
          ];
          run = "plugin sudo -- link --relative";
          desc = "sudo link relative path";
        }
        {
          # sudo ln
          on = [
            "R"
            "p"
            "L"
          ];
          run = "plugin sudo -- hardlink";
          desc = "sudo hardlink";
        }
        {
          # sudo touch/mkdir
          on = [
            "R"
            "a"
          ];
          run = "plugin sudo -- create";
          desc = "sudo create";
        }
        {
          # sudo trash
          on = [
            "R"
            "d"
          ];
          run = "plugin sudo -- remove";
          desc = "sudo trash";
        }
        {
          # sudo delete
          on = [
            "R"
            "D"
          ];
          run = "plugin sudo -- remove --permanently";
          desc = "sudo delete";
        }
      ];
    };
  };
}
