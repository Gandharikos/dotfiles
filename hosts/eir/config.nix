{
  dot = {
    primaryUser = "johnson";
    device.type = "laptop";
    keyboard = {
      layout = "qwerty";
      backend = "karabiner";
    };
    users.johnson.home.my.gui = {
      terminal = {
        default = "rex";
        size = 14;
      };
      browser.default = "chrome";
    };
  };

  nixporn.transparent = true;
}
