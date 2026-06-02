{ ... }:
{
  imports = [
    # ./aseprite/aseprite.nix           # pixel art editor
    # ./audacious/audacious.nix         # music player
    ./bat.nix                         # better cat command
    ./claude.nix                      # claude code AI assistant
    ./browser.nix                     # firefox based browser
    ./btop.nix                        # resouces monitor
    # ./cava.nix                        # audio visualizer
    ./direnv.nix
    # ./discord.nix                     # discord
    ./fastfetch/fastfetch.nix         # fetch tool
    ./fcitx5.nix                      # Vietnamese input method
    ./fzf.nix                         # fuzzy finder
    # ./gaming.nix                      # packages related to gaming
    ./ghostty/ghostty.nix             # terminal
    ./git.nix                         # version control
    ./gnome.nix                       # gnome apps
    ./gtk.nix                         # gtk theme
    ./hyprland                        # window manager
    ./kitty.nix                       # terminal
    ./lazygit.nix
    # ./micro.nix                       # nano replacement
    ./nemo.nix                        # file manager
    ./nvim.nix                        # neovim editor
    # ./obsidian.nix
    ./p10k/p10k.nix
    ./packages                        # other packages
    # ./pomo/pomo.nix                   # TUI Pomodoro timer
    # ./retroarch.nix
    ./rclone.nix                      # Google Drive mount + wallpaper sync
    ./watson.nix                      # time tracker + Google Drive sync
    ./rofi/rofi.nix                   # launcher
    ./../../scripts/scripts.nix       # personal scripts
    ./slack.nix                       # slack
    ./ssh.nix                         # ssh config
    # ./spicetify.nix                   # spotify client
    ./superfile/superfile.nix         # terminal file manager
    ./swaylock.nix                    # lock screen
    ./swayosd.nix                     # brightness / volume wiget
    ./swaync/swaync.nix               # notification deamon
    ./vscodium                        # vscode fork
    ./waybar                          # status bar
    ./wallpaper-rotate.nix            # auto random wallpaper timer
    ./waypaper.nix                    # GUI wallpaper picker
    ./xdg-mimes.nix                   # xdg config
    ./zsh                             # shell
  ];
}
