{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dot.zellij) template;
in
{
  config = mkIf (builtins.hasAttr "default_tab_template" template) {
    programs.zellij.layouts.ai = {
      layout._children = [
        template
        {
          tab = {
            _props = {
              name = "ai";
              focus = true;
            };
            _children = [
              {
                pane = {
                  split_direction = "Vertical";
                  _children = [
                    { pane.size = "75%"; }
                    {
                      pane = {
                        size = "25%";
                        split_direction = "Horizontal";
                        _children = [
                          { pane.command = "gemini"; }
                          { pane.command = "claude"; }
                          { pane.command = "codex"; }
                        ];
                      };
                    }
                  ];
                };
              }
            ];
          };
        }
      ];
    };
  };
}
