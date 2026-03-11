{pkgs, ...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # archives
    # keep-sorted start
    p7zip
    unzipNLS
    xz
    zip
    zstd
    # keep-sorted end

    # text processing
    # keep-sorted start
    gawk
    gnugrep
    gnused
    jq
    # keep-sorted end

    # networking tools
    # keep-sorted start
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    dnsutils # `dig` + `nslookup`
    ipcalc # it is a calculator for the IPv4/v6 addresses
    iperf3
    ldns # replacement of `dig`, it provide the command `drill`
    mtr # A network diagnostic tool
    nmap # A utility for network discovery and security auditing
    socat # replacement of openbsd-netcat
    # keep-sorted end

    # misc
    # keep-sorted start
    file
    findutils
    gnutar
    tree
    which
    # keep-sorted end

    # system call monitoring
    # keep-sorted start
    bpftrace # powerful tracing tool
    lsof # list open files
    ltrace # library call monitoring
    strace # system call monitoring
    tcpdump # network sniffer
    # keep-sorted end

    # system monitoring
    # keep-sorted start
    btop
    iftop
    iotop
    nmon
    sysbench
    sysstat
    # keep-sorted end

    # system tools
    # keep-sorted start
    dmidecode # a tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
    ethtool
    hdparm # for disk performance, command
    lm_sensors # for `sensors` command
    parted
    pciutils # lspci
    psmisc # killall/pstree/prtstat/fuser/...
    sbctl # a tool to control the system behavior
    usbutils # lsusb
    # keep-sorted end
  ];
}
