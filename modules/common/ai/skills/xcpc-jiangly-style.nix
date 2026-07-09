{ pkgs, ... }:
let
  jianglyStyle = pkgs.fetchFromGitHub {
    owner = "lihaoze123";
    repo = "jiangly-s-code-style-for-xcpc";
    rev = "e3343cc1efd85e09da0e9200da35a8445a16bff6";
    hash = "sha256-PeJvK8rc6IMXpP+TMIHkd/AXdy2TsRPPTFAaDQMGfR0=";
  };

  jianglySkill = jianglyStyle + "/skills/xcpc-jiangly-style";
in
{
  "xcpc-jiangly-style" = {
    content = builtins.readFile (jianglySkill + "/SKILL.md");
    path = jianglySkill;
  };
}
