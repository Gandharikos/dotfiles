_: _final: prev: {
  ast-grep = prev.ast-grep.overrideAttrs (_old: {
    # Disable tests due to macOS-specific test failure
    # Error: test_scan_invalid_rule_id fails with "Illegal byte sequence (os error 92)"
    doCheck = false;
  });
}
