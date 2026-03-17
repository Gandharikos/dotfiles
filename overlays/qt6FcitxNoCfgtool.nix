_: _final: prev: {
  qt6Packages = prev.qt6Packages.overrideScope (
    _qt6final: qt6prev: {
      fcitx5-with-addons = qt6prev.fcitx5-with-addons.override { withConfigtool = false; };
    }
  );
}
