{ host, config, ... }:
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      ##### Font #####
      font-family = "JetBrainsMono Nerd Font";
      font-size = if (host == "p14s") then 20 else 16;

      ##### Theme #####
      theme = "Monokai Pro";
      background-opacity = 0.8;
      background-blur-radius = 20;
      cursor-style = "block";
      adjust-cursor-thickness = 1;

      selection-clear-on-copy = true;
      mouse-hide-while-typing = true;

      ##### Window #####;
      window-padding-balance = true;
      window-padding-color = "extend";
      window-decoration = "none";
      window-theme = "ghostty";
      window-inherit-working-directory = false;

      resize-overlay = "never";
      confirm-close-surface = false;
      app-notifications = "no-clipboard-copy";

      bell-features = "no-attention,no-audio,no-system,no-title,no-border";

      gtk-single-instance = false;
      gtk-tabs-location = "top";
      gtk-wide-tabs = false;
      gtk-toolbar-style = "flat";
      gtk-custom-css = "${config.xdg.configHome}/ghostty/styles/tabs.css";

      auto-update = "off";

      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = false;

      ##### Keybinds #####
      keybind = [
        "clear"

        "ctrl+shift+r=reload_config"
        "ctrl+shift+a=select_all"
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"

        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_tab:this"
        "ctrl+tab=next_tab"
        "ctrl+shift+tab=previous_tab"
        "alt+digit_1=goto_tab:1"
        "alt+digit_2=goto_tab:2"
        "alt+digit_3=goto_tab:3"
        "alt+digit_4=goto_tab:4"

        "ctrl+equal=increase_font_size:1"
        "ctrl++=increase_font_size:1"
        "ctrl+-=decrease_font_size:1"
        "ctrl+0=reset_font_size"

        "shift+page_down=scroll_page_down"
        "shift+page_up=scroll_page_up"
        "ctrl+shift+k=reset_terminal"
      ];
    };

    themes.gruvbox = {
      background = "1d2021";
      foreground = "fbf1c7";

      cursor-color = "D5C4A1";

      selection-background = "cell-foreground";
      selection-foreground = "cell-background";

      palette = [
        "0=32302f"
        "1=cc241d"
        "2=98971a"
        "3=d79921"
        "4=458588"
        "5=b16286"
        "6=689d6a"
        "7=ebdbb2"

        "8=928374"
        "9=fb4934"
        "10=b8bb26"
        "11=fabd2f"
        "12=83a598"
        "13=d3869b"
        "14=8ec07c"
        "15=fbf1c7"
      ];
    };
  };

  xdg.configFile."ghostty/styles/tabs.css".source = ./styles/tabs.css;
}
