{ ... }:
{
  programs.lazygit = {
    enable = true;

    settings = {
      gui.border = "single";
      gui.showFileTree = false;
    };
  };
}
