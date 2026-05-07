{ lib, ... }:
let
  getNixFiles' =
    path:
    let
      entries = builtins.readDir path;
    in
    lib.filter (name: lib.hasSuffix ".nix" name) (builtins.attrNames entries);
  mergeAttrs' = attrsList: lib.foldl' (acc: attrs: acc // attrs) { } attrsList;
in
{
  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  relativeToConfig = lib.path.append ../config/.;
  getFile = relativePath: lib.path.append ../. relativePath;
  # Import all .nix files from a directory and merge them into a single attribute set
  # Convenience function combining importFiles and mergeAttrs
  # Usage: importDir ./hooks { inherit pkgs; }
  importDir =
    path: args:
    let
      nixFiles = getNixFiles' path;
      imported = map (name: import (path + "/${name}") args) nixFiles;
    in
    mergeAttrs' imported;
  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          name: _type:
          (_type == "directory" && builtins.pathExists (path + "/${name}/default.nix")) # include directories
          || (
            (name != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" name) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );

  sourceLua =
    path:
    let
      name = builtins.baseNameOf path;

      # ssourcePath
      sourcePath = "nvim/lua/plugins/extras/${path}";

      # xdg.configFile."key"
      key = "nvim/lua/plugins/${name}";
    in
    # 返回一个 attrset，动态定义了 `${key}.source`
    {
      "${key}".source = lib.dot.relativeToConfig sourcePath;
    };
}
