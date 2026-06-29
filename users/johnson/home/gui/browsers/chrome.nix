{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.apps.chrome;
  enable = osConfig.dot.gui.enable && cfg.enable;

  # On hybrid-GPU hosts (e.g. ymir: AMD iGPU drives the display, NVIDIA is the
  # dGPU) the system-wide LIBVA_DRIVER_NAME=nvidia forces browser video decode
  # onto the NVIDIA card. Since the compositor runs on the AMD iGPU, every
  # decoded frame is then copied across PCIe back to the iGPU — that cross-GPU
  # copy is what stutters on high-fps/AV1 YouTube playback. Decode on the same
  # GPU that composites (radeonsi) to avoid the copy entirely.
  isHybridAmdNvidia = osConfig.dot.device.gpu == "nvidia" && osConfig.dot.device.cpu == "amd";

  chrome =
    if isHybridAmdNvidia then
      pkgs.symlinkJoin {
        name = "google-chrome-igpu-decode";
        paths = [ pkgs.google-chrome ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for bin in google-chrome google-chrome-stable; do
            if [ -e "$out/bin/$bin" ]; then
              wrapProgram "$out/bin/$bin" \
                --set LIBVA_DRIVER_NAME radeonsi \
                --add-flags "--enable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks" \
                --add-flags "--ignore-gpu-blocklist" \
                --add-flags "--ozone-platform-hint=auto"
            fi
          done
        '';
      }
    else
      pkgs.google-chrome;
in
{
  options.my.gui.apps.chrome = {
    enable = mkEnableOption "chrome" // {
      default = config.my.gui.browser.default == "google-chrome";
    };
  };

  config = mkIf enable {
    home = {
      packages = [ chrome ];
    };
  };
}
