{inputs, ...}: {
  # Export overlays coming from inputs directly
  emacs = inputs.emacs-overlay.overlay;
  inherit (inputs.niri.overlays) niri;
}
