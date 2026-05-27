{ inputs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
  };

  xdg.configFile."nvim".source = inputs.astronvim-template;
}
