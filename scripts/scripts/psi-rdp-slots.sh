#!/usr/bin/env bash
# Check RDP sessions trên các PSI hosts — liệt kê account trống

PSI_SUBNET="192.168.1"
PSI_HOST_OCTETS=(216 217 236 237)
SSH_USER="administrator"
SSH_KEY="$HOME/.ssh/id_ed25519"
JUMP="goline@10.10.1.132,goline@103.139.12.115"
MAX_SESSIONS=2

EXCLUDE_PATTERN="^(administrator|admin|guest|defaultaccount|wdagutilityaccount)$"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=8 -o LogLevel=ERROR"

# ── Colors ($'...' để nhúng ESC char thực, không phải literal \033) ───────────
R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'
B=$'\033[1m';  DIM=$'\033[2m'; RST=$'\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────

_ssh() {
  local out err_out
  err_out=$(mktemp)
  out=$(ssh $SSH_OPTS -J "$JUMP" "$SSH_USER@$1" "$2" 2>"$err_out")
  if [[ -z "$out" ]]; then
    # Nếu stdout rỗng thì trả stderr (Windows SSH đôi khi dùng stderr)
    out=$(cat "$err_out")
  fi
  rm -f "$err_out"
  printf '%s' "$out"
}

_filter_sys() {
  grep -viE "$EXCLUDE_PATTERN"
}

# Unique non-admin usernames từ query user (kể cả Disc), dedup
_occupied() {
  echo "$1" | tail -n +2 \
    | awk '{print tolower($1)}' \
    | grep -v "^$" \
    | _filter_sys \
    | sort -u
}

# Parse net user → account thực (bỏ built-in)
_all_accounts() {
  echo "$1" | tr -d '\r' \
    | grep -vE "^(User accounts|---|The command|\s*$)" \
    | tr -s ' ' '\n' \
    | tr '[:upper:]' '[:lower:]' \
    | grep -v "^$" \
    | _filter_sys \
    | sort -u
}

# Parse 1 dòng query user → "username|state|idle|logon"
# query user có 2 format tùy có/không có SESSIONNAME:
#   sp02  rdp-tcp#1  3  Active  34       9/12/2026 2:06 PM   (có sessionname)
#   sp01             4  Disc    1:45     9/12/2026 2:21 PM   (không có sessionname)
_parse_session_line() {
  awk '{
    user = tolower($1)
    # $2 là số thuần → không có sessionname
    if ($2 ~ /^[0-9]+$/) {
      state = $3; idle = $4; logon = $5" "$6" "$7
    } else {
      state = $4; idle = $5; logon = $6" "$7" "$8
    }
    print user"|"state"|"idle"|"logon
  }'
}

# ── Main ──────────────────────────────────────────────────────────────────────
printf "\n${B}PSI RDP Slot Check — %s${RST}\n" "$(date '+%Y-%m-%d %H:%M')"
printf '%s\n' "────────────────────────────────────────────────────"

available_hosts=()

for octet in "${PSI_HOST_OCTETS[@]}"; do
  host="${PSI_SUBNET}.${octet}"
  printf "\n${B}[192.168.1.%s]${RST}\n" "$octet"

  quser=$(_ssh "$host" "query user")

  if ! echo "$quser" | grep -q "USERNAME"; then
    err=$(echo "$quser" | grep -v "^$" | head -1)
    printf "  ${R}OFFLINE${RST}"
    [[ -n "$err" ]] && printf " — %s" "$err"
    printf "\n"
    continue
  fi

  # ── Session table ────────────────────────────────────────────────────────
  printf "  ${DIM}%-20s %-8s %-10s %s${RST}\n" "User" "State" "Idle" "Logon"
  printf "  ${DIM}%-20s %-8s %-10s %s${RST}\n" "────────────────────" "────────" "──────────" "──────────────────"

  while IFS= read -r line; do
    [[ -z "$(echo "$line" | tr -d ' \r')" ]] && continue
    IFS='|' read -r uname state idle logon <<< "$(echo "$line" | _parse_session_line)"

    case "$state" in
      Active) state_fmt="${G}Active  ${RST}" ;;
      Disc)   state_fmt="${Y}Disc    ${RST}" ;;
      *)      state_fmt="${DIM}${state}${RST}" ;;
    esac

    is_admin=false
    echo "$uname" | grep -qiE "^(administrator|admin)$" && is_admin=true

    if $is_admin; then
      printf "  ${DIM}%-20s${RST} %s${DIM}%-10s %s${RST}\n" "$uname" "$state_fmt" "$idle" "$logon"
    else
      printf "  %-20s %s%-10s %s\n" "$uname" "$state_fmt" "$idle" "$logon"
    fi
  done <<< "$(echo "$quser" | tail -n +2)"

  # ── Slot / empty check ───────────────────────────────────────────────────
  # Đếm TẤT CẢ session (kể admin) cho slot capacity
  all_occupied=$(echo "$quser" | tail -n +2 \
    | awk '{print tolower($1)}' | grep -v "^$" | sort -u)
  if [[ -z "$all_occupied" ]]; then count=0
  else count=$(echo "$all_occupied" | wc -l | tr -d ' '); fi

  # Chỉ dùng non-admin để tìm account trống
  non_admin_occupied=$(echo "$all_occupied" | _filter_sys)

  printf "\n"
  if [[ "$count" -ge "$MAX_SESSIONS" ]]; then
    printf "  ${R}FULL %d/%d slot${RST}\n" "$count" "$MAX_SESSIONS"
    continue
  fi

  printf "  ${G}Còn %d slot trống${RST}\n" "$((MAX_SESSIONS - count))"

  net_out=$(_ssh "$host" "net user")
  all_accs=$(_all_accounts "$net_out")
  empty_accs=$(comm -23 <(echo "$all_accs") <(echo "$non_admin_occupied" | sort))

  if [[ -n "$empty_accs" ]]; then
    printf "  ${G}Account trống: %s${RST}\n" "$(echo "$empty_accs" | tr '\n' ' ')"
    available_hosts+=("192.168.1.$octet")
  else
    printf "  ${Y}Không có account trống${RST}\n"
  fi
done

printf "\n%s\n" "────────────────────────────────────────────────────"
if [[ ${#available_hosts[@]} -gt 0 ]]; then
  printf "${G}Host còn slot: %s${RST}\n\n" "${available_hosts[*]}"
else
  printf "${R}Tất cả host đều full.${RST}\n\n"
fi
