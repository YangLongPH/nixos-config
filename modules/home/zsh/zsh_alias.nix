{ ... }:
{
  programs.zsh = {
    shellAliases = {
      # Editor
      v  = "nvim";
      vi = "vim";

      # Utils
      c = "clear";
      cd = "z";
      tt = "gtrash put";
      cat = "bat";
      nano = "micro";
      code = "codium";
      diff = "delta --diff-so-fancy --side-by-side";
      less = "bat";
      copy = "wl-copy";
      f = "superfile";
      py = "python";
      ipy = "ipython";
      icat = "kitten icat";
      ssh = "TERM=xterm-256color ssh";
      # Windows OpenSSH: admin accounts dung administrators_authorized_keys
      ssh-copy-id-win = "ssh-copy-id -s -i ~/.ssh/id_ed25519.pub -t \"/ProgramData/ssh/administrators_authorized_keys\"";
      # Windows OpenSSH: non-admin accounts (sp01, sp02...) dung ~/.ssh/authorized_keys
      ssh-copy-id-win-user = "ssh-copy-id -s -i ~/.ssh/id_ed25519.pub";
      dsize = "du -hs";
      pdf = "tdf";
      open = "xdg-open";
      space = "ncdu";
      man = "batman";

      l = "eza --icons -a --group-directories-first -1 --no-user --long"; # EZA_ICON_SPACING=2
      tree = "eza --icons --tree --group-directories-first";

      # Nixos
      cdnix = "cd ~/nixos-config && codium ~/nixos-config";
      ns = "nom-shell --run zsh";
      nsp = "nom-shell --run zsh -p";
      nd = "nom develop --command zsh";
      nb = "nom build";
      nc = "nh-notify nh clean all --keep 5";
      nft = "nh-notify nh os test";
      nfs = "nh-notify nh os switch";
      nfu = "nh-notify nh os switch --update";
      nsearch = "nh search";

      # AWS
      aws-cc = "aws --profile course-cast";

      # python
      piv = "python -m venv .venv";
      psv = "source .venv/bin/activate";
    };
  };
}
