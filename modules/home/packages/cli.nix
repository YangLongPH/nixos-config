{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Better core utils
    duf                               # disk information
    eza                               # ls replacement
    fd                                # find replacement
    gping                             # ping with a graph
    gtrash                            # rm replacement, put deleted files in system trash
    hexyl                             # hex viewer
    man-pages                         # extra man pages
    ncdu                              # disk space
    ripgrep                           # grep replacement
    tldr

    ## Tools / useful cli
    aoc-cli                           # Advent of Code command-line tool
    asciinema
    asciinema-agg
    binsider
    bitwise                           # cli tool for bit / hex manipulation
    broot                             # tree files view
    caligula                          # User-friendly, lightweight TUI for disk imaging
    python3Packages.huggingface-hub    # HuggingFace CLI (hf)
    hyperfine                         # benchmarking tool
    just                              # command runner (makefile like)
    pastel                            # cli to manipulate colors
    scooter                           # Interactive find and replace in the terminal
    swappy                            # snapshot editing tool
    tdf                               # cli pdf viewer
    tokei                             # project line counter
    translate-shell                   # cli translator
    woomer
    yt-dlp-light

    ## Time tracking
    watson                            # CLI time tracker

    ## Database
    usql                              # universal SQL CLI (Oracle, Postgres, MySQL, ...)
    rlwrap                            # readline wrapper (adds history/editing to sqlplus etc.)
    lazysql                           # TUI for databases
    lazydocker                        # TUI for Docker

    ## TUI
    epy                               # ebook reader
    gtt                               # google translate TUI
    toipe                             # typing test in the terminal
    ttyper                            # cli typing test

    ## Networking
    grpcurl                              # gRPC curl
    nettools                             # netstat, ifconfig, etc.
    nmap                                 # network scanner
    inetutils                            # telnet, ftp, etc.
    samba                                # SMB client (smbclient, smbget)

    ## Monitoring / fetch
    htop
    onefetch                          # fetch utility for git repo
    speedtest-cli                     # internet speed test
    wavemon                           # monitoring for wireless network devices

    ## Fun / screensaver
    asciiquarium-transparent
    cbonsai
    cmatrix
    countryfetch
    cowsay
    figlet
    fortune
    lavat
    lolcat
    pipes
    sl
    tty-clock

    ## Multimedia
    imv
    lowfi
    mpv

    ## Utilities
    findutils                            # find, xargs, locate
    entr                              # perform action when file change
    ffmpeg
    file                              # Show file information
    jq                                # JSON processor
    yq-go                             # YAML processor
    killall
    libnotify
    mimeo
    openssl
    pamixer                           # pulseaudio command line mixer
    playerctl                         # controller for media players
    poweralertd
    socat
    udiskie                           # Automounter for removable media
    unrar
    unzip
    wget
    wl-clipboard                      # clipboard utils for wayland (wl-copy, wl-paste)
    xdg-utils
    xdotool                              # simulate keyboard/mouse input (X11/XWayland only)
    ydotool                              # simulate keyboard/mouse input (Wayland native)

    # winetricks
    # wineWow64Packages.waylandFull
  ];
}
