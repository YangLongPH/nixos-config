{ pkgs, username, ... }:
let
  identity = {
    name  = "YangLong";
    email = "yanglong.ph@gmail.com";
  };
in
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        inherit (identity) name email;
      };

      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      pull.ff = "only";
      color.ui = true;

      url = {
        "git@github.com:".insteadOf = [
          "gh:"
          "https://github.com/"
        ];
        "git@github.com:frost-phoenix/".insteadOf = "fp:";
      };

      core = {
        excludesFile = "/home/${username}/.config/git/.gitignore";
        hooksPath    = "/home/${username}/.git-hooks";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = false;

    options = {
      line-numbers = true;
      side-by-side = true;
      diff-so-fancy = true;
      navigate = true;
    };
  };

  home.packages = with pkgs; [
    gh
    serie
  ];

  xdg.configFile."git/.gitignore".text = ''
    .vscode
    .direnv
  '';

  # Git hooks — auto-log time to Redmine on commit
  # API key goes in ~/.git-hooks/secrets (NOT managed here, not committed)
  home.file.".git-hooks/post-commit" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # post-commit: auto-log time to Redmine khi commit có #NNNNN trong message.
      #
      # Files trong ~/.git-hooks/:
      #   redmine-logtime.conf  — config defaults (managed by Nix)
      #   secrets               — REDMINE_API_KEY=... (tạo tay, không commit)
      #   logtime.log           — lịch sử log (tự tạo)
      #
      # Mốc thời gian lấy từ Redmine (created_on của entry cuối cùng hôm nay).

      HOOK_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
      CONF="$HOOK_DIR/redmine-logtime.conf"
      LOG="$HOOK_DIR/logtime.log"

      # --- Default config ---
      REDMINE_URL="https://pm2.goline.vn"
      REDMINE_API_KEY=""
      WORK_START="08:00"
      LUNCH_START="11:30"
      LUNCH_END="13:00"
      ACTIVITY_ID=9
      MIN_MINUTES=15

      # shellcheck source=/dev/null
      [[ -f "$CONF" ]]            && source "$CONF"
      [[ -f "$HOOK_DIR/secrets" ]] && source "$HOOK_DIR/secrets"

      if [[ -z "$REDMINE_API_KEY" ]]; then
        echo "[redmine-logtime] ✗ REDMINE_API_KEY chưa set trong $HOOK_DIR/secrets" >&2
        exit 0
      fi

      # --- Extract ticket number ---
      COMMIT_SUBJECT=$(git log -1 --format="%s" 2>/dev/null)
      COMMIT_BODY=$(git log -1 --format="%b" 2>/dev/null | tr '\n' ' ')
      COMMIT_MSG="$COMMIT_SUBJECT $COMMIT_BODY"
      TICKET=$(echo "$COMMIT_MSG" | grep -oE '#[0-9]+' | head -1 | tr -d '#')
      [[ -z "$TICKET" ]] && exit 0

      # --- Lấy mốc thời gian từ Redmine ---
      today=$(date +%Y-%m-%d)
      now_ts=$(date +%s)
      now_hm=$(date +%H:%M)

      ts_today() { date -d "$today $1:00" +%s; }
      work_start_ts=$(ts_today "$WORK_START")
      lunch_start_ts=$(ts_today "$LUNCH_START")
      lunch_end_ts=$(ts_today "$LUNCH_END")

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

      # Nếu start nằm trong lunch window → advance lên lunch_end (tránh lunch ăn hết net time)
      if (( start_ts >= lunch_start_ts && start_ts < lunch_end_ts )); then
        start_ts=$lunch_end_ts
      fi

      start_hm=$(date -d "@$start_ts" +%H:%M)

      # --- Tính giờ, trừ nghỉ trưa ---
      total_secs=$(( now_ts - start_ts ))
      (( total_secs < 0 )) && total_secs=0

      ov_s=$(( start_ts > lunch_start_ts ? start_ts : lunch_start_ts ))
      ov_e=$(( now_ts   < lunch_end_ts   ? now_ts   : lunch_end_ts   ))
      (( ov_e > ov_s )) && total_secs=$(( total_secs - (ov_e - ov_s) ))

      total_minutes=$(( total_secs / 60 ))

      if (( total_minutes < MIN_MINUTES )); then
        hours_fmt=$(awk "BEGIN { printf \"%.2f\", $total_secs / 3600 }")
        min_fmt=$(awk "BEGIN { printf \"%.2f\", $MIN_MINUTES / 60 }")
        echo "[redmine-logtime] #$TICKET: ''${hours_fmt}h < ''${min_fmt}h min, bỏ qua ($start_hm→$now_hm)"
        exit 0
      fi

      quarters=$(( (total_minutes + 7) / 15 ))
      hours=$(awk "BEGIN { printf \"%.2f\", $quarters * 0.25 }")

      # --- Gọi Redmine API ---
      COMMENT="$(echo "$COMMIT_SUBJECT" | head -c 180 | sed 's/\\/\\\\/g; s/"/\\"/g') ($start_hm→$now_hm)"
      resp_file=$(mktemp)

      http_code=$(curl -s \
        -o "$resp_file" \
        -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
        -d "{\"time_entry\":{\"issue_id\":$TICKET,\"spent_on\":\"$today\",\"hours\":$hours,\"activity_id\":$ACTIVITY_ID,\"comments\":\"$COMMENT\"}}" \
        "$REDMINE_URL/time_entries.json" 2>/dev/null)

      if [[ "$http_code" == "201" ]]; then
        entry_id=$(jq -r '.time_entry.id' "$resp_file" 2>/dev/null)
        echo "[redmine-logtime] ✓ #$TICKET: ''${hours}h logged ($start_hm→$now_hm, entry #$entry_id)"
        printf '{"ts":"%s","ticket":%s,"from":"%s","to":"%s","hours":%s,"entry_id":%s,"status":"ok","comment":"%s"}\n' \
          "$(date -Iseconds)" "$TICKET" "$start_hm" "$now_hm" "$hours" "''${entry_id:-null}" "$COMMENT" >> "$LOG"
      else
        body=$(cat "$resp_file")
        echo "[redmine-logtime] ✗ #$TICKET: HTTP $http_code — $body" >&2
        printf '{"ts":"%s","ticket":%s,"from":"%s","to":"%s","hours":%s,"status":"http_%s","error":"%s"}\n' \
          "$(date -Iseconds)" "$TICKET" "$start_hm" "$now_hm" "$hours" "$http_code" \
          "$(echo "$body" | sed 's/"/\\"/g')" >> "$LOG"
      fi

      rm -f "$resp_file"
    '';
  };

  home.file.".git-hooks/redmine-logtime.conf".text = ''
    # redmine-logtime.conf — config defaults, managed by Nix (đừng sửa trực tiếp)
    # Để override REDMINE_API_KEY và các biến khác: tạo ~/.git-hooks/secrets
    #   echo 'REDMINE_API_KEY="your-key-here"' > ~/.git-hooks/secrets

    REDMINE_URL="https://pm2.goline.vn"

    WORK_START="08:00"
    LUNCH_START="11:30"
    LUNCH_END="13:00"

    ACTIVITY_ID=9        # 9=Development 10=Test 16=Fix Re-open 20=Review/Merge
    MIN_MINUTES=15       # bỏ qua nếu dưới ngưỡng này (15 phút = 0.25h)
  '';

  programs.zsh.shellAliases = {
    g = "lazygit";
    gf = "onefetch --number-of-file-churns 0 --no-color-palette";

    gs = "git status";
    gcl = "git clone";
    gd = "git diff --word-diff=color";

    ga = "git add";
    gaa = "git add --all";

    gc = "git commit";
    gcm = "git commit -m";

    gpl = "git pull";
    gplo = "git pull origin";

    gps = "git push";
    gpso = "git push origin";
    gpst = "git push --tags";
    gtag = "git tag -ma";

    gm = "git merge";
    gb = "git branch";
    gch = "git checkout";
    gchb = "git checkout -b";

    glog = "git log --oneline --decorate --graph";
    glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'";
    glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all";
    glols = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat";
  };
}
