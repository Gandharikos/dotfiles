{ lib, ... }:
let
  capitalize =
    str:
    lib.strings.concatStrings [
      (lib.strings.toUpper (lib.strings.substring 0 1 str))
      (lib.strings.substring 1 (lib.strings.stringLength str - 1) str)
    ];
  # removeHashTag = palette:
  #   builtins.mapAttrs (
  #     _: value: let
  #       len = builtins.stringLength value;
  #       prefix = builtins.substring 0 1 value;
  #     in
  #       if prefix == "#"
  #       then builtins.substring 1 (len - 1) value
  #       else value
  #   )
  #   palette;

  removeHashtag =
    color:
    let
      len = builtins.stringLength color;
      prefix = builtins.substring 0 1 color;
    in
    if prefix == "#" then builtins.substring 1 (len - 1) color else color;

  removeHashtags = colors: builtins.map removeHashtag colors;

  # removeHashtag { a= "#ff0000"; b = "#0f0"; colors = { c1 = "#000000"; }; } => { a = "ff0000"; b = "0f0"; colors = { c1 = "000000"; }; }
  removeHashtags' =
    palette:
    let
      go =
        value:
        if lib.isAttrs value then
          removeHashtags' value
        else if lib.isList value then
          removeHashtags value
        else if lib.isString value then
          removeHashtag value
        else
          value;
    in
    builtins.mapAttrs (_: go) palette;

  hexDigits = "0123456789abcdef";

  toHex2 =
    n:
    let
      high = builtins.div n 16;
      low = lib.trivial.mod n 16;
    in
    builtins.substring high 1 hexDigits + builtins.substring low 1 hexDigits;

  rgba =
    hex: alpha:
    let
      h = removeHashtag hex;
      a =
        if lib.isString alpha then
          removeHashtag alpha
        else if lib.isFloat alpha then
          toHex2 (builtins.floor (alpha * 255))
        else
          builtins.toString alpha;
    in
    "rgba(${h}${a})";

  gradient =
    h1: a1: h2: a2: angle:
    let
      c1 = rgba h1 a1;
      c2 = rgba h2 a2;
      deg = "${toString angle}deg";
    in
    lib.strings.concatStringsSep " " [
      c1
      c2
      deg
    ];
  # gradient = args: gradient' args.h1 args.a1 args.h2 args.a2 args.angle;

  # Convert #RRGGBB or #RGB to 0xRRGGBB format
  toHex =
    color:
    let
      hex = removeHashtag color;
    in
    "0x${hex}";
in
{
  inherit
    removeHashtag
    removeHashtags
    removeHashtags'
    capitalize
    rgba
    gradient
    toHex
    ;
}
