{ pkgs }:
let
  dmsPluginsRepo = pkgs.fetchFromGitHub {
    owner = "AvengeMedia";
    repo = "dms-plugins";
    rev = "829922a8f11949b1c13ae8bd14d7176f9165b6f5";
    hash = "sha256-KYx+n1stxLT4R9IDVRx3/Cl7TjCcBZjnQchbrXaBT2o=";
  };
in
{
  dankPomodoroTimer = {
    enable = true;
    src = "${dmsPluginsRepo}/DankPomodoroTimer";
  };
  catWidget = {
    enable = true;
    src = pkgs.fetchFromGitHub {
      owner = "xi-ve";
      repo = "cat-dms";
      rev = "eb7b5138b672be3c06445dd80de6bc30c3076030";
      hash = "sha256-KD2G805Hq0K9aPW9Aq4hNo2XKji4kzdc24M4AcRhsPk=";
    };
  };
  dmsScreenshot = {
    enable = true;
    src = pkgs.fetchFromGitHub {
      owner = "JDKamalakar";
      repo = "DMS-Screenshot";
      rev = "695a12428b0cc85db0e9cd6b469f776342950fa7";
      hash = "sha256-3KQCIrVclcqaQiwZhv7dwNbTjPL/+jzi8I3h0yn35w8=";
    };
  };
  emojiLauncher = {
    enable = true;
    src = pkgs.fetchFromGitHub {
      owner = "devnullvoid";
      repo = "dms-emoji-launcher";
      rev = "1c0a7d337a52b48f9499060076703a35e8dd4f4f";
      hash = "sha256-NQ14YenDiNK2VqXQ3z7jAkatbSRtYJHhOhvv7AJlUD8=";
    };
  };
  screenRecorder = {
    enable = true;
    src = pkgs.fetchFromGitHub {
      owner = "arqueon";
      repo = "dms-screen-recorder";
      rev = "7206b590d69a165d30b5bbb66b033f1a15b49aff";
      hash = "sha256-ndH8KHH+gzFIXWceqeUmy/w7oGj7ZvCEIacBfV1D+KU=";
    };
  };
}
