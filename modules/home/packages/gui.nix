{ pkgs, ... }:
{
  home.file.".config/autostart/remmina-applet.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  home.packages = with pkgs; [
    ## Multimedia
    amberol # music player
    audacity
    gimp
    media-downloader
    obs-studio
    pavucontrol
    video-trimmer
    vlc

    ## Office
    libreoffice
    gnome-calculator
    foliate # EPUB reader

    ## Utility
    dconf-editor
    gnome-disk-utility
    popsicle
    mission-center # GUI resources monitor
    freerdp
    remmina
    zenity

    ## Database
    dbeaver-bin

    ## Diagramming
    drawio
    penpot-desktop

    ## Level editor
    ldtk
    tiled
  ];
}
