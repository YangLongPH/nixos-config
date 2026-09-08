{ ... }:
{
  programs.qutebrowser = {
    enable = true;

    settings = {
      content.javascript.enabled = true;
      content.blocking.enabled = true;
      content.blocking.method = "both";

      fonts.default_size = "11pt";
      fonts.default_family = "monospace";

      tabs.position = "top";
      tabs.show = "multiple";

      scrolling.smooth = true;

      editor.command = [ "ghostty" "-e" "nvim" "{}" ];
    };

    keyBindings = {
      normal = {
        "<Space>o" = "set-cmd-text -s :open";
        "<Space>O" = "set-cmd-text -s :open -t";
        "J" = "tab-prev";
        "K" = "tab-next";
        "d" = "tab-close";
        "u" = "undo";
        "H" = "back";
        "L" = "forward";
        "<Ctrl-l>" = "set-cmd-text -s :open {url}";
      };
    };

    searchEngines = {
      DEFAULT = "https://www.google.com/search?q={}";
      "g" = "https://www.google.com/search?q={}";
      "gh" = "https://github.com/search?q={}";
      "yt" = "https://www.youtube.com/results?search_query={}";
    };
  };
}
