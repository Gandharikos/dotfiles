{
  dot = {
    primaryUser = "johnson";
    device.type = "laptop";
    keyboard = {
      layout = "qwerty";
      backend = "karabiner";
    };
    services.karabiner.devices = [
      {
        vendorId = 1278;
        productId = 33;
      }
    ];
    users.johnson.home.my.gui = {
      terminal = {
        default = "rex";
        size = 14;
      };
      browser.default = "google-chrome";
    };
  };

  nixporn.transparent = true;
}
