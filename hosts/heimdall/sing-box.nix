# First stage: reuse ymir's host proxy before testing LAN forwarding.
# No DHCP server or second transparent-proxy core.
{
  lib,
  pkgs,
  self,
  ...
}:
let
  ruleRevision = "12381b9cde2576c8b0bd43bb09af463ec7a75d12";
  ruleFile =
    name: kind: hash:
    pkgs.fetchurl {
      inherit name hash;
      url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/${ruleRevision}/geo/${kind}/cn.srs";
    };
in
{
  dot.networking = {
    # The shared TUN has IPv4 and IPv6 addresses. The management link still rejects RA.
    enableIPv6 = lib.mkForce true;
    proxy = {
      enable = true;
      backend = "sing-box";
      autoStart = true;
      profile = {
        enable = true;
        secretsFile = "${self}/secrets/services/proxy.yml";
        tailnet.domain = "tail2cfd9e.ts.net";
        # Do not block DNS/proxy startup on downloading public rule sets.
        # Refresh these pinned snapshots deliberately alongside host updates.
        singBox.ruleSetFiles = {
          cn-domain =
            ruleFile "cn-domain.srs" "geosite"
              "sha256-Doo79iJm/t2LTdfBG7C/sWrjToZyi3RxeUEeDfvc8cs=";
          cn-ip = ruleFile "cn-ip.srs" "geoip" "sha256-rVClSDF/Q3A1c16pqhF/9cVPURJNlWWhRinHwKNNuRg=";
        };
      };
    };
  };
}
