{ inputs, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
  };

  xdg.configFile."nvim".source = inputs.astronvim-template;

  home.sessionVariables = {
    JDTLS_JAVA = "${pkgs.temurin-bin-21}/bin/java";
  };
}
