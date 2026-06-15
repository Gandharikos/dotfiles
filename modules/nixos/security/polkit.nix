{
  config,
  ...
}:
{
  # have polkit log all actions
  security = {
    polkit.enable = true;

    # this should only be installed on graphical desktop.
    soteria.enable =
      config.dot.gui.enable
      && !config.dot.gui.desktop.cosmic.enable
      && config.dot.gui.desktop.shell != "noctalia";
  };
}
