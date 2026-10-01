{ pkgs, inputs, lib, ... }:
let
  claude-pkg = inputs.claude-code.packages.${pkgs.system}.default;
  mcpServers = {
    playwright = {
      command = "npx";
      args = [
        "@playwright/mcp@latest"
        "--executable-path"
        "/etc/profiles/per-user/yanglong/bin/google-chrome-stable"
        "--headless"
        "--no-sandbox"
      ];
    };
  };
  defaultSettings = builtins.toJSON {
    permissions = {
      defaultMode = "bypassPermissions";
    };
    theme = "dark";
    skipDangerousModePermissionPrompt = true;
    inherit mcpServers;
  };
  settingsFile = pkgs.writeText "claude-settings.json" defaultSettings;
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

  # Copy settings.json only if not already present — Claude Code needs to write to this file
  # at runtime (plugins, MCP servers), so we cannot use home.file (which creates read-only symlinks).
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for dir in .claude-work .claude-work2 .claude-personal; do
      target="$HOME/$dir/settings.json"
      if [ ! -f "$target" ]; then
        $DRY_RUN_CMD mkdir -p "$HOME/$dir"
        $DRY_RUN_CMD cp ${settingsFile} "$target"
        $DRY_RUN_CMD chmod 644 "$target"
      fi
    done
  '';
}
