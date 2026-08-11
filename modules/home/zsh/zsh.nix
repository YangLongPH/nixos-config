{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;

    # enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "mvn"
        "npm"
        "podman"
        "tmux"
        "wd"
        "command-not-found"
        "fancy-ctrl-z"
        "argocd"
        "docker"
        "docker-compose"
        "gh"
        "sudo"
        "kubectl"
        "terraform"
      ];
    };

    history = {
      share = true;
      ignoreSpace = true;
      ignoreDups = true;
      saveNoDups = true;
      findNoDups = true;
      expireDuplicatesFirst = true;
    };

    plugins = [
      {
        # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-autopair";
        src = "${pkgs.zsh-autopair}/share/zsh/zsh-autopair";
        file = "autopair.zsh";
      }
      {
        name = "zig-zsh-completions-plugin";
        file = "zig-shell-completions.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "ziglang";
          repo = "shell-completions";
          rev = "31d3ad12890371bf467ef7143f5c2f31cfa7b7c1";
          sha256 = "1fzl1x56b4m11wajk1az4p24312z7wlj2cqa3b519v30yz9clgr0";
        };
      }
    ];

    completionInit = ''
      # Load Zsh modules
      # zmodload zsh/zle
      # zmodload zsh/zpty
      # zmodload zsh/complist

      # Initialize colors
      autoload -Uz colors
      colors

      # Initialize completion system
      # autoload -U compinit
      # compinit
      _comp_options+=(globdots)

      # Load edit-command-line for ZLE
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey "^e" edit-command-line

      # General completion behavior
      zstyle ':completion:*' completer _extensions _complete _approximate

      # Use cache
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

      # Complete the alias
      zstyle ':completion:*' complete true

      # Autocomplete options
      zstyle ':completion:*' complete-options true

      # Completion matching control
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' keep-prefix true

      # Group matches and describe
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-grouped false
      zstyle ':completion:*' list-separator '''
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*:matches' group 'yes'
      zstyle ':completion:*:warnings' format '%F{red}%B-- No match for: %d --%b%f'
      zstyle ':completion:*:messages' format '%d'
      zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
      zstyle ':completion:*:descriptions' format '[%d]'

      # Colors
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

      # Directories
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
      zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true

      # Sort
      zstyle ':completion:*' sort false
      zstyle ":completion:*:git-checkout:*" sort false
      zstyle ':completion:*' file-sort modification
      zstyle ':completion:*:eza' sort false
      zstyle ':completion:complete:*:options' sort false
      zstyle ':completion:files' sort false

      # fzf-tab
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons  -a --group-directories-first -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-pad 4
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'
    '';

    initContent = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      DISABLE_AUTO_UPDATE=true
      DISABLE_MAGIC_FUNCTIONS=true
      export "MICRO_TRUECOLOR=1"
      export PATH="$HOME/.local/bin:$PATH"
      export JAVA_HOME="${pkgs.temurin-bin-11}"
      alias jcli='${pkgs.temurin-bin-21}/bin/java -jar ~/.jenkins/jenkins-cli.jar -s http://10.10.1.120:8443/ -ssh -user goline -i ~/.ssh/id_ed25519'

      setopt hist_verify

      source ~/.p10k.zsh

      # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
      # - The first argument to the function ($1) is the base path to start traversal
      # - See the source code (completion.{bash,zsh}) for the details.
      _fzf_compgen_path() {
        fd --hidden --exclude .git . "$1"
      }

      # Use fd to generate the list for directory completion
      _fzf_compgen_dir() {
        fd --type=d --hidden --exclude .git . "$1"
      }

      # Advanced customization of fzf options via _fzf_comprun function
      # - The first argument to the function is the name of the command.
      # - You should make sure to pass the rest of the arguments to fzf.
      _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
          cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
          ssh)          fzf --preview 'dig {}'                   "$@" ;;
          *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
        esac
      }

      # Make sure that the terminal is in application mode when zle is active, since
      # only then values from $terminfo are valid
      if (( ''${+terminfo[smkx]} )) && (( ''${+terminfo[rmkx]} )); then
        function zle-line-init() {
          echoti smkx
        }
        function zle-line-finish() {
          echoti rmkx
        }
        zle -N zle-line-init
        zle -N zle-line-finish
      fi

      # rtlog <ticket> [comment] [activity_id]
      # Log time to Redmine manually — same logic as post-commit hook.
      # Uses ~/.git-hooks/redmine-logtime.conf + secrets for config.
      rtlog() {
        local TICKET="''${1#\#}"
        if [[ -z "$TICKET" ]]; then
          echo "Usage: rtlog <ticket> [comment] [activity_id]" >&2
          return 1
        fi

        local HOOK_DIR="$HOME/.git-hooks"
        local CONF="$HOOK_DIR/redmine-logtime.conf"
        local LOG="$HOOK_DIR/logtime.log"

        local REDMINE_URL="https://pm2.goline.vn"
        local REDMINE_API_KEY=""
        local WORK_START="08:00"
        local WORK_END="18:00"
        local LUNCH_START="11:30"
        local LUNCH_END="13:00"
        local ACTIVITY_ID=9
        local MIN_MINUTES=15

        [[ -f "$CONF" ]]             && source "$CONF"
        [[ -f "$HOOK_DIR/secrets" ]] && source "$HOOK_DIR/secrets"

        if [[ -z "$REDMINE_API_KEY" ]]; then
          echo "[redmine-logtime] ✗ REDMINE_API_KEY chưa set trong $HOOK_DIR/secrets" >&2
          return 1
        fi

        local COMMENT="''${2:-}"
        [[ -n "$3" ]] && ACTIVITY_ID="$3"

        local today now_ts now_hm
        today=$(date +%Y-%m-%d)
        now_ts=$(date +%s)
        now_hm=$(date +%H:%M)

        local work_start_ts work_end_ts lunch_start_ts lunch_end_ts
        work_start_ts=$(date -d "$today ''${WORK_START}:00" +%s)
        work_end_ts=$(date -d "$today ''${WORK_END}:00" +%s)
        lunch_start_ts=$(date -d "$today ''${LUNCH_START}:00" +%s)
        lunch_end_ts=$(date -d "$today ''${LUNCH_END}:00" +%s)

        local last_created start_ts
        last_created=$(curl -sf \
          -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
          "$REDMINE_URL/time_entries.json?user_id=me&spent_on=$today&limit=100" \
          2>/dev/null \
          | jq -r '[.time_entries[].created_on] | max // empty')

        if [[ -n "$last_created" ]]; then
          start_ts=$(date -d "$last_created" +%s)
        else
          (( now_ts < work_start_ts )) && start_ts=$now_ts || start_ts=$work_start_ts
        fi

        if (( start_ts >= lunch_start_ts && start_ts < lunch_end_ts )); then
          start_ts=$lunch_end_ts
        fi

        local start_hm
        start_hm=$(date -d "@$start_ts" +%H:%M)

        local total_secs
        total_secs=$(( now_ts - start_ts ))
        (( total_secs < 0 )) && total_secs=0

        local ov_s ov_e
        ov_s=$(( start_ts > lunch_start_ts ? start_ts : lunch_start_ts ))
        ov_e=$(( now_ts   < lunch_end_ts   ? now_ts   : lunch_end_ts   ))
        (( ov_e > ov_s )) && total_secs=$(( total_secs - (ov_e - ov_s) ))

        local total_minutes=$(( total_secs / 60 ))

        if (( total_minutes < MIN_MINUTES )); then
          local hours_fmt min_fmt
          hours_fmt=$(awk "BEGIN { printf \"%.2f\", $total_secs / 3600 }")
          min_fmt=$(awk "BEGIN { printf \"%.2f\", $MIN_MINUTES / 60 }")
          echo "[redmine-logtime] [''${start_hm}→''${now_hm}] #$TICKET: ''${hours_fmt}h < ''${min_fmt}h min, bỏ qua"
          return 0
        fi

        local quarters=$(( (total_minutes + 14) / 15 ))
        local hours=$(awk "BEGIN { printf \"%.2f\", $quarters * 0.25 }")

        (( now_ts > work_end_ts )) && \
          echo "[redmine-logtime] ⚠️  ngoài giờ (''${now_hm} > $WORK_END): vẫn log ''${hours}h"

        [[ -z "$COMMENT" ]] && COMMENT="manual log"
        local comment_api
        comment_api="[''${start_hm}→''${now_hm}] $(echo "$COMMENT" | head -c 230 | sed 's/\\/\\\\/g; s/"/\\"/g')"

        local resp_file http_code
        resp_file=$(mktemp)

        http_code=$(curl -s \
          -o "$resp_file" \
          -w "%{http_code}" \
          -X POST \
          -H "Content-Type: application/json" \
          -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
          -d "{\"time_entry\":{\"issue_id\":$TICKET,\"spent_on\":\"$today\",\"hours\":$hours,\"activity_id\":$ACTIVITY_ID,\"comments\":\"$comment_api\"}}" \
          "$REDMINE_URL/time_entries.json" 2>/dev/null)

        if [[ "$http_code" == "201" ]]; then
          local entry_id
          entry_id=$(jq -r '.time_entry.id' "$resp_file" 2>/dev/null)
          echo "[redmine-logtime] [''${start_hm}→''${now_hm}] ✓ #$TICKET: ''${hours}h logged"
          printf '{"ts":"%s","ticket":%s,"from":"%s","to":"%s","hours":%s,"entry_id":%s,"status":"ok","comment":"%s"}\n' \
            "$(date -Iseconds)" "$TICKET" "$start_hm" "$now_hm" "$hours" "''${entry_id:-null}" "$comment_api" >> "$LOG"
        else
          local body
          body=$(cat "$resp_file")
          echo "[redmine-logtime] ✗ #$TICKET: HTTP $http_code — $body" >&2
          printf '{"ts":"%s","ticket":%s,"from":"%s","to":"%s","hours":%s,"status":"http_%s","error":"%s"}\n' \
            "$(date -Iseconds)" "$TICKET" "$start_hm" "$now_hm" "$hours" "$http_code" \
            "$(echo "$body" | sed 's/"/\\"/g')" >> "$LOG"
        fi

        rm -f "$resp_file"
      }

      _WIRED_PROXY_URL="http://10.10.1.90:3128/"
      _WIRED_NO_PROXY="localhost,127.0.0.1,192.168.1.*,10.10.*,.goline,*.goline.vn"

      # Sync proxy env vào terminal hiện tại dựa theo flag file do NM dispatcher tạo.
      _proxy_sync() {
        local flag="$HOME/.cache/wired-proxy-active"
        if [[ -f $flag && -z $HTTPS_PROXY ]]; then
          export HTTP_PROXY="$_WIRED_PROXY_URL"
          export HTTPS_PROXY="$_WIRED_PROXY_URL"
          export NO_PROXY="$_WIRED_NO_PROXY"
          export http_proxy="$_WIRED_PROXY_URL"
          export https_proxy="$_WIRED_PROXY_URL"
          export no_proxy="$_WIRED_NO_PROXY"
        elif [[ ! -f $flag && -n $HTTPS_PROXY ]]; then
          unset HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
        fi
      }
      precmd_functions+=(_proxy_sync)

      # Manual toggle — shell env + Hyprland env (GUI apps) + flag file (precmd).
      proxy-on() {
        export HTTP_PROXY="$_WIRED_PROXY_URL"
        export HTTPS_PROXY="$_WIRED_PROXY_URL"
        export NO_PROXY="$_WIRED_NO_PROXY"
        export http_proxy="$_WIRED_PROXY_URL"
        export https_proxy="$_WIRED_PROXY_URL"
        export no_proxy="$_WIRED_NO_PROXY"
        hyprctl keyword env "HTTP_PROXY,$_WIRED_PROXY_URL"
        hyprctl keyword env "HTTPS_PROXY,$_WIRED_PROXY_URL"
        hyprctl keyword env "http_proxy,$_WIRED_PROXY_URL"
        hyprctl keyword env "https_proxy,$_WIRED_PROXY_URL"
        hyprctl keyword env "NO_PROXY,$_WIRED_NO_PROXY"
        hyprctl keyword env "no_proxy,$_WIRED_NO_PROXY"
        touch ~/.cache/wired-proxy-active
        echo "Proxy ON → $_WIRED_PROXY_URL"
      }

      proxy-off() {
        unset HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
        hyprctl keyword unsetenv HTTP_PROXY
        hyprctl keyword unsetenv HTTPS_PROXY
        hyprctl keyword unsetenv http_proxy
        hyprctl keyword unsetenv https_proxy
        hyprctl keyword unsetenv NO_PROXY
        hyprctl keyword unsetenv no_proxy
        rm -f ~/.cache/wired-proxy-active
        echo "Proxy OFF"
      }

      redmine-time() {
        local from=''${1:-$(date -d "$(date +%Y-%m-%d) - $(( $(date +%u) - 1 )) days" +%Y-%m-%d)}
        local to=''${2:-$(date -d "$(date +%Y-%m-%d) + $(( 7 - $(date +%u) )) days" +%Y-%m-%d)}
        curl -s "https://pm2.goline.vn/time_entries.json?user_id=152&from=''${from}&to=''${to}&limit=100" \
          -H "X-Redmine-API-Key: ef7b894244ccd7700945ad6832ffe2b3040ddb8b" | python3 -c "
import json, sys
from collections import defaultdict
data = json.load(sys.stdin)
by_project = defaultdict(float)
by_day = defaultdict(float)
for e in data.get('time_entries', []):
    by_project[e['project']['name']] += e['hours']
    by_day[e['spent_on']] += e['hours']
print('--- By project ---')
[print(f'  {h:.2f}h  {p}') for p, h in sorted(by_project.items(), key=lambda x: -x[1])]
print('--- By day ---')
[print(f'  {d}: {by_day[d]:.2f}h') for d in sorted(by_day)]
print(f'TOTAL: {sum(by_project.values()):.2f}h')
"
      }
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
