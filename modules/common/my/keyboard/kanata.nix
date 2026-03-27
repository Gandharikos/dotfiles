{ lib, pkgs, ... }:
{
  # Helper to generate the kanata configuration string based on the platform.
  mkKanataConfig =
    {
      isLinux ? pkgs.stdenv.isLinux,
      isDarwin ? pkgs.stdenv.isDarwin,
      includeDefCfg ? true,
    }:
    let
      # Define the bottom row based on the OS (6 keys each)
      # Linux/PC: lctl lmet lalt           spc            ralt rctl
      # Darwin/Mac: lctl lalt lmet           spc            rmet ralt
      srcBottomRow =
        if isLinux then
          "lctl lmet lalt           spc            ralt rmet"
        else
          "lctl lalt lmet           spc            rmet ralt";

      # Base layer bottom row (the remap):
      # Linux: swap lctl and lmet, map ralt to rmet
      # Darwin: lctl lmet lalt (swap for consistency if desired, but Mac already uses Cmd for shortcuts)
      # User previously had: lmet lctl lalt spc rmet for Linux.
      baseBottomRow =
        if isLinux then
          "lmet lctl lalt           spc            rmet ralt"
        else
          "lctl lmet lalt           spc            @hyper rmet";

      # Print Screen key varies by platform in kanata.
      prtScKey = if isLinux then "prtsc" else "f13";
    in
    ''
      ;; Generated Kanata configuration
      ${lib.optionalString includeDefCfg ''
        (defcfg
          process-unmapped-keys yes
          ${lib.optionalString isLinux ''
            linux-continue-if-no-devs-found yes
          ''}
          ${lib.optionalString isDarwin ''
            macos-dev-names-include ("Apple Internal Keyboard / Trackpad")
          ''}
        )
      ''}

      (defsrc
        tab  q    w    e    r    t    y    u    i    o    p bspc
        caps a    s    d    f    g    h    j    k    l    ;    '    ret
        lsft z    x    c    v    b    n    m    ,    .    /
        ${srcBottomRow}
      )

      ;; vars
      (defvar
        tapping-term 150
        quick-tap 125
      )

      (defalias
        caps_word (caps-word 1000)
        sft (one-shot $tapping-term lsft)
        escctrl (tap-hold-press $tapping-term $quick-tap esc lctl)
        smart_sft (tap-dance 200 (@sft @caps_word))
        tab-mod (tap-hold-press $tapping-term $quick-tap tab (layer-while-held tab_layer))
        ${lib.optionalString isDarwin ''
          hyper (multi lctl lalt lmet)
        ''}
      )

      (deflayer base
        @tab-mod   _    _    _    _    _    _    _    _    _    _    _
        @escctrl   _    _    _    _    _    _    _    _    _    _    _    _
        @smart_sft _    _    _    _    _    _    _    _    _    _
        ${baseBottomRow}
      )

      (deflayer tab_layer
        _    C-f12    _    _    _    _    _    _    _    _    ${prtScKey} del
        _    _        _    _    _    _    left down up   right _    _    _
        _    _        _    _    _    _    _    _    _    _    _
        _    _    _              _         _    _
      )
    '';
}
