{ pkgs, inputs, ... }:
let
  claude-pkg = inputs.claude-code.packages.${pkgs.system}.default;
in
{
  home.packages = [ claude-pkg ];

  # Use CLAUDE_CONFIG_DIR=~/.claude-work; reference store path to avoid alias recursion
  programs.zsh.shellAliases = {
    claude   = "CLAUDE_CONFIG_DIR=~/.claude-work ${claude-pkg}/bin/claude";
    claude-w = "CLAUDE_CONFIG_DIR=~/.claude-work ${claude-pkg}/bin/claude";
    claude-p = "CLAUDE_CONFIG_DIR=~/.claude-personal ${claude-pkg}/bin/claude";
  };

  # Personal Claude profile with bypassPermissions mode enabled by default
  home.file.".claude-personal/settings.json".text = builtins.toJSON {
    permissions = {
      mode = "bypassPermissions";
    };
  };
}
