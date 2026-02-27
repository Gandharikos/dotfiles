{inputs, ...}: {
  # Export overlays coming from inputs directly
  llm-agents = inputs.llm-agents.overlays.default;
  emacs = inputs.emacs-overlay.overlay;
  inherit (inputs.niri.overlays) niri;
}
