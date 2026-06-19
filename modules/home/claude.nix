{ pkgs, inputs, ... }:
let
  claude-pkg = inputs.claude-code.packages.${pkgs.system}.default;
in
{
  home.packages = [ claude-pkg ];

  # Use CLAUDE_CONFIG_DIR=~/.claude-work; reference store path to avoid alias recursion
  programs.zsh.shellAliases = {
    claude   = "CLAUDE_CONFIG_DIR=~/.claude-work ${claude-pkg}/bin/claude";
    claude-w  = "CLAUDE_CONFIG_DIR=~/.claude-work ${claude-pkg}/bin/claude";
    claude-w2 = "CLAUDE_CONFIG_DIR=~/.claude-work2 ${claude-pkg}/bin/claude";
    claude-p = "CLAUDE_CONFIG_DIR=~/.claude-personal ${claude-pkg}/bin/claude";
  };

  home.file.".claude-work/settings.json".text = builtins.toJSON {
    permissions = {
      defaultMode = "bypassPermissions";
    };
    theme = "dark";
    skipDangerousModePermissionPrompt = true;
  };

  home.file.".claude-work2/settings.json".text = builtins.toJSON {
    permissions = {
      defaultMode = "bypassPermissions";
    };
    theme = "dark";
    skipDangerousModePermissionPrompt = true;
  };

  home.file.".claude-personal/settings.json".text = builtins.toJSON {
    permissions = {
      defaultMode = "bypassPermissions";
    };
    theme = "dark";
    skipDangerousModePermissionPrompt = true;
  };
}
