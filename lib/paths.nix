{ lib, ... }:
let
  getNixFiles' =
    path: builtins.readDir path |> builtins.attrNames |> lib.filter (name: lib.hasSuffix ".nix" name);
  mergeAttrs' = attrsList: attrsList |> lib.foldl' (acc: attrs: acc // attrs) { };
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
    path: args: getNixFiles' path |> map (name: import (path + "/${name}") args) |> mergeAttrs';
  scanPaths =
    path:
    builtins.readDir path
    |> lib.attrsets.filterAttrs (
      name: _type:
      (_type == "directory" && builtins.pathExists (path + "/${name}/default.nix")) # include directories
      || (
        (name != "default.nix") # ignore default.nix
        && (lib.strings.hasSuffix ".nix" name) # include .nix files
      )
    )
    |> builtins.attrNames
    |> builtins.map (f: (path + "/${f}"));

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
