{
  appimageTools,
  fetchurl,
  stdenvNoCC,
  xdg-user-dirs,
}:
let
  pname = "wechat";

  sources = {
    aarch64-linux = {
      version = "4.1.1.4";
      src = fetchurl {
        url = "https://web.archive.org/web/20260311102559if_/https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.AppImage";
        hash = "sha256-YlWJxT62tXDaNwYVpsPMC5elFH8fsbI1HjTQn6ePiPo=";
      };
    };
    x86_64-linux = {
      version = "4.1.1.4";
      src = fetchurl {
        url = "https://web.archive.org/web/20260311102439if_/https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
        hash = "sha256-XxAvFnlljqurGPDgRr+DnuCKbdVvgXBPh02DLHY3Oz8=";
      };
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;
  inherit (sources.${system} or (throw "Unsupported system: ${system}")) version src;

  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      patchelf --replace-needed libtiff.so.5 libtiff.so $out/opt/wechat/wechat
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;

  src = appimageContents;

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${appimageContents}/wechat.desktop $out/share/applications/
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/

    substituteInPlace $out/share/applications/wechat.desktop --replace-fail AppRun wechat
  '';

  extraPreBwrapCmds = ''
    export PATH="${xdg-user-dirs}/bin:$PATH"

    XDG_DOCUMENTS_DIR="''${XDG_DOCUMENTS_DIR:-$(xdg-user-dir DOCUMENTS)}"
    if [[ -z "''${XDG_DOCUMENTS_DIR}" ]]; then
      echo 'Error: failed to resolve XDG_DOCUMENTS_DIR'
      exit 1
    fi

    WECHAT_DATA_DIR="''${XDG_DOCUMENTS_DIR}/WeChat_Data"
    WECHAT_HOME_DIR="''${WECHAT_DATA_DIR}/home"
    WECHAT_FILES_DIR="''${WECHAT_DATA_DIR}/xwechat_files"

    mkdir -p "''${WECHAT_FILES_DIR}" "''${WECHAT_HOME_DIR}"
    ln -snf "''${WECHAT_FILES_DIR}" "''${WECHAT_HOME_DIR}/xwechat_files"
  '';

  extraBwrapArgs = [
    "--tmpfs /home"
    "--tmpfs /root"
    "--bind \${WECHAT_HOME_DIR} \${HOME}"
    "--bind \${WECHAT_FILES_DIR} \${WECHAT_FILES_DIR}"
    "--chdir \${HOME}"
    "--setenv QT_QPA_PLATFORM xcb"
    "--setenv QT_AUTO_SCREEN_SCALE_FACTOR 1"
    "--setenv QT_IM_MODULE fcitx"
    "--setenv GTK_IM_MODULE fcitx"
  ];
  chdirToPwd = false;
  unshareNet = false;
  unshareIpc = true;
  unsharePid = true;
  unshareUts = true;
  unshareCgroup = true;
  privateTmp = true;
}
