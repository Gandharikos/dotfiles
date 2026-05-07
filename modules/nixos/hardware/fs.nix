{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) attrNames filterAttrs hasAttr;
  btrfsFileSystems = filterAttrs (_: v: v.fsType == "btrfs") config.fileSystems;
  btrfsScrubTargets =
    if hasAttr "/" btrfsFileSystems then
      [ "/" ]
    else if hasAttr "/btr_pool" btrfsFileSystems then
      [ "/btr_pool" ]
    else
      attrNames btrfsFileSystems;
in
{
  config = mkMerge [
    {
      # discard blocks that are not in use by the filesystem, good for SSDs health
      services.fstrim = {
        enable = true;
        interval = "weekly";
      };
    }

    # clean btrfs devices
    (mkIf (btrfsScrubTargets != [ ]) {
      services.btrfs.autoScrub = {
        enable = true;
        interval = "weekly";
        fileSystems = btrfsScrubTargets;
      };
    })
  ];
}
