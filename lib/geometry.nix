{lib, ...}: {
  vec2 = x: y:
    lib.strings.concatStringsSep " " [
      (toString x)
      (toString y)
    ];
}
