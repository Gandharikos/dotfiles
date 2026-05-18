{
  programs.zellij.settings.keybinds._children = [
    {
      renametab._children = [
        {
          bind = {
            _args = [ "Esc" ];
            _children = [
              { UndoRenameTab = { }; }
              { SwitchToMode._args = [ "tab" ]; }
            ];
          };
        }
      ];
    }
    {
      renamepane._children = [
        {
          bind = {
            _args = [ "Esc" ];
            _children = [
              { UndoRenamePane = { }; }
              { SwitchToMode._args = [ "pane" ]; }
            ];
          };
        }
      ];
    }
    {
      shared_among = {
        _args = [
          "renametab"
          "renamepane"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl c" ];
              _children = [ { SwitchToMode._args = [ "normal" ]; } ];
            };
          }
        ];
      };
    }
  ];
}
