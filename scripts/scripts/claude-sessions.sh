#!/usr/bin/env bash
# claude-sessions — list Claude Code sessions with session ID, path, title
# Simulates --resume but shows what Claude omits: session ID + project path
#
# Usage: claude-sessions [-a|--all] [-p|--pick] [-n N] [--cwd PATH]
# Hotkey Alt+R in zsh → --pick --all → puts "claude-w2 --resume <id>" in BUFFER

set -uo pipefail

# ── colors (only when stdout is a terminal) ───────────────────────────────
if [[ -t 1 ]]; then
    DIM='\e[2m' BOLD='\e[1m' RST='\e[0m' YLW='\e[33m' CYN='\e[36m' GRN='\e[32m' MAG='\e[35m'
else
    DIM='' BOLD='' RST='' YLW='' CYN='' GRN='' MAG=''
fi

# ── args ──────────────────────────────────────────────────────────────────
ALL=0 PICK=0 LIMIT=30 TARGET_CWD="$PWD"

usage() {
    cat <<'EOF'
Usage: claude-sessions [options]

Options:
  -a, --all        All projects (default: current directory only)
  -p, --pick       fzf picker → prints resume command (for zsh widget or copy-paste)
  -n N, --limit N  Max sessions (default: 30)
  --cwd PATH       Override project path for filter
  -h, --help       Show this help

Profile aliases: claude / claude-w (work)  claude-w2 (work2)  claude-p (personal)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)   ALL=1;;
        -p|--pick)  PICK=1;;
        -n|--limit) LIMIT="$2"; shift;;
        --cwd)      TARGET_CWD="$2"; shift;;
        -h|--help)  usage; exit 0;;
        *)          echo "Unknown option: $1" >&2; usage >&2; exit 1;;
    esac
    shift
done

command -v jq  &>/dev/null || { echo "Error: jq required" >&2; exit 1; }
[[ $PICK -eq 1 ]] && { command -v fzf &>/dev/null || { echo "Error: fzf required for --pick" >&2; exit 1; }; }

# ── discover all ~/.claude-* dirs that have a projects/ subdir ────────────
mapfile -t CLAUDE_DIRS < <(
    for d in "$HOME"/.claude-*; do
        [[ -d "$d/projects" ]] && echo "$d"
    done 2>/dev/null
)
[[ ${#CLAUDE_DIRS[@]} -eq 0 ]] && { echo "No ~/.claude-* config dirs found" >&2; exit 1; }

# ── helpers ───────────────────────────────────────────────────────────────
# CWD → project folder key: replace ALL / with - (including leading slash)
path_to_key() { printf '%s' "$1" | sed 's|/|-|g'; }

short_home() { printf '%s' "$1" | sed "s|^$HOME|~|"; }

trunc() {
    local s="$1" n="$2"
    [[ ${#s} -gt $n ]] && printf '%s…' "${s:0:$((n-1))}" || printf '%s' "$s"
}

# cfg_dir basename → short profile label
cfg_to_profile() {
    case "$(basename "$1")" in
        .claude-work)     echo "work";;
        .claude-work2)    echo "work2";;
        .claude-personal) echo "personal";;
        *)                echo "$(basename "$1" | sed 's/^\.claude-//')";;
    esac
}

# profile → zsh alias to invoke that claude instance
profile_to_alias() {
    case "$1" in
        work)     echo "claude";;
        work2)    echo "claude-w2";;
        personal) echo "claude-p";;
        *)        echo "claude";;
    esac
}

# ── collect JSONL files to scan ───────────────────────────────────────────
declare -a SCAN_FILES=()   # each entry: "filepath\tcfg_dir"

for cfg_dir in "${CLAUDE_DIRS[@]}"; do
    if [[ $ALL -eq 1 ]]; then
        while IFS= read -r -d '' f; do
            [[ "$f" == */subagents/* ]] && continue
            SCAN_FILES+=("$f"$'\t'"$cfg_dir")
        done < <(find "$cfg_dir/projects" -maxdepth 2 -name "*.jsonl" -print0 2>/dev/null)
    else
        pkey="$(path_to_key "$TARGET_CWD")"
        pdir="$cfg_dir/projects/$pkey"
        [[ -d "$pdir" ]] || continue
        while IFS= read -r -d '' f; do
            SCAN_FILES+=("$f"$'\t'"$cfg_dir")
        done < <(find "$pdir" -maxdepth 1 -name "*.jsonl" -print0 2>/dev/null)
    fi
done

if [[ ${#SCAN_FILES[@]} -eq 0 ]]; then
    if [[ $ALL -eq 0 ]]; then
        echo "No sessions for: $TARGET_CWD" >&2
        echo "(Try --all to see all projects)" >&2
    else
        echo "No sessions found in: ${CLAUDE_DIRS[*]}" >&2
    fi
    exit 1
fi

# ── parse one JSONL file → one TSV row ───────────────────────────────────
# columns: epoch \t mtime \t session_id \t cwd \t title \t file \t cfg_dir \t profile
parse_session() {
    local file="$1" cfg_dir="$2"
    local epoch mtime sid cwd title first_user profile

    sid="$(basename "$file" .jsonl)"
    epoch="$(stat -c '%Y' "$file" 2>/dev/null)"
    mtime="$(date -d "@$epoch" "+%Y-%m-%d %H:%M" 2>/dev/null)"
    profile="$(cfg_to_profile "$cfg_dir")"

    title="$(jq -r 'select(.type == "ai-title") | .aiTitle' "$file" 2>/dev/null | head -1)"
    first_user="$(jq -rc 'select(.type == "user")' "$file" 2>/dev/null | head -1)"
    cwd="$(printf '%s' "$first_user" | jq -r '.cwd // ""' 2>/dev/null)"

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$epoch" "$mtime" "$sid" "$cwd" "${title:-<no title>}" "$file" "$cfg_dir" "$profile"
}

# ── collect, sort newest-first, limit ────────────────────────────────────
declare -a ROWS=()
for entry in "${SCAN_FILES[@]}"; do
    file="${entry%%$'\t'*}"
    cfg="${entry##*$'\t'}"
    ROWS+=("$(parse_session "$file" "$cfg")")
done

mapfile -t SORTED < <(printf '%s\n' "${ROWS[@]}" | sort -t$'\t' -k1,1rn | head -n "$LIMIT")

[[ ${#SORTED[@]} -eq 0 ]] && { echo "No sessions found" >&2; exit 1; }

# ── display ───────────────────────────────────────────────────────────────
sep() { printf '%.0s─' $(seq 1 "$1"); }

if [[ $PICK -eq 0 ]]; then
    if [[ $ALL -eq 0 ]]; then
        printf "${BOLD}Sessions for:${RST} %s\n\n" "$(short_home "$TARGET_CWD")"
        printf "${DIM}%-16s  %-8s  %-36s  %-45s  %s${RST}\n" "Updated" "Profile" "Session ID" "Title" "File"
        printf "${DIM}%-16s  %-8s  %-36s  %-45s  %s${RST}\n" "$(sep 16)" "$(sep 8)" "$(sep 36)" "$(sep 45)" "$(sep 40)"
        for row in "${SORTED[@]}"; do
            IFS=$'\t' read -r epoch mtime sid cwd title file cfg_dir profile <<< "$row"
            printf "${DIM}%s${RST}  ${MAG}%-8s${RST}  ${YLW}%s${RST}  %-45s  ${CYN}%s${RST}\n" \
                "$mtime" "$profile" "$sid" "$(trunc "$title" 45)" "$(short_home "$file")"
        done
    else
        printf "${BOLD}All Claude sessions${RST} (newest %d)\n\n" "$LIMIT"
        printf "${DIM}%-16s  %-8s  %-36s  %-45s  %s${RST}\n" "Updated" "Profile" "Session ID" "Title" "File"
        printf "${DIM}%-16s  %-8s  %-36s  %-45s  %s${RST}\n" \
            "$(sep 16)" "$(sep 8)" "$(sep 36)" "$(sep 45)" "$(sep 40)"
        for row in "${SORTED[@]}"; do
            IFS=$'\t' read -r epoch mtime sid cwd title file cfg_dir profile <<< "$row"
            printf "${DIM}%s${RST}  ${MAG}%-8s${RST}  ${YLW}%s${RST}  %-45s  ${CYN}%s${RST}\n" \
                "$mtime" "$profile" "$sid" "$(trunc "$title" 45)" "$(short_home "$file")"
        done
    fi
    echo ""
    printf "${DIM}Resume: <alias> --resume <session-id>  (aliases: claude, claude-w2, claude-p)${RST}\n"
    exit 0
fi

# ── pick mode: fzf → print resume command ────────────────────────────────
# Format: <session_id> <profile> <mtime> <project> <branch> <title>
# First two fields are machine-readable; fzf lets user filter by any column
declare -a FZF_LINES=()
for row in "${SORTED[@]}"; do
    IFS=$'\t' read -r epoch mtime sid cwd title file cfg_dir profile <<< "$row"
    FZF_LINES+=("$(printf '%-36s  %-8s  %s  %-45s  %s' \
        "$sid" "$profile" "$mtime" \
        "$(trunc "$title" 45)" \
        "$(short_home "$file")")")
done

selected="$(printf '%s\n' "${FZF_LINES[@]}" \
    | fzf --no-sort \
          --header='Alt+R: claude sessions  |  type to filter by project/title/profile  |  Enter=resume  Esc=cancel')"

[[ -z "$selected" ]] && exit 1

sid="$(printf '%s' "$selected" | awk '{print $1}')"
profile="$(printf '%s' "$selected" | awk '{print $2}')"
alias_name="$(profile_to_alias "$profile")"

printf '%s --resume %s' "$alias_name" "$sid"
