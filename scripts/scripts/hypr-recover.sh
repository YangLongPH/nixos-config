#!/usr/bin/env bash
# Fix session sau khi Hyprland crash (SEGV o CMonitor::onConnect, xem hyprland.nix)
# roi tu relaunch vao Safe Mode / hyprctl reload:
#   - nap lai plugin hy3 (Safe Mode/reload khong tu nap lai plugin)
#   - reload config de dispatcher hy3:* duoc dang ky
#   - bat lai cac exec-once daemon bi chet theo Hyprland luc crash
set -uo pipefail

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
export XDG_RUNTIME_DIR

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    for f in "$XDG_RUNTIME_DIR"/wayland-*; do
        case "$f" in
            *.lock|*.sock) continue ;;
        esac
        [ -S "$f" ] && WAYLAND_DISPLAY="$(basename "$f")" && break
    done
    export WAYLAND_DISPLAY
fi

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)
    export HYPRLAND_INSTANCE_SIGNATURE
fi

echo "hypr-recover: WAYLAND_DISPLAY=$WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"

conf="$HOME/.config/hypr/hyprland.conf"

if ! hyprctl plugins list 2>/dev/null | grep -q "^Plugin hy3"; then
    plugin_path=$(grep -h '^plugin' "$conf" 2>/dev/null | head -1 | sed 's/^plugin *= *//')
    if [ -n "$plugin_path" ] && [ -f "$plugin_path" ]; then
        hyprctl plugin load "$plugin_path"
        echo "hypr-recover: da nap lai plugin hy3 ($plugin_path)"
    else
        echo "hypr-recover: khong tim thay path plugin hy3 trong $conf" >&2
    fi
else
    echo "hypr-recover: plugin hy3 da duoc nap san"
fi

hyprctl reload
echo "hypr-recover: da reload config"

# Nix wrap cac GUI binary nen comm thuc te la ".<ten>-wrapped", khong phai "<ten>".
# Match theo full command line (path /bin/<ten>) de khong bi false-negative gay
# spawn trung (double bar).
daemons=(
    "waybar:waybar"
    "swaync:swaync"
    "nm-applet:nm-applet"
    "poweralertd:poweralertd"
    "udiskie:udiskie --automount --notify --smart-tray"
    "wl-paste:wl-paste --watch cliphist store"
    "wl-clip-persist:wl-clip-persist --clipboard both"
)

for entry in "${daemons[@]}"; do
    name="${entry%%:*}"
    cmd="${entry#*:}"
    if ! pgrep -f "/bin/$name" > /dev/null; then
        runbg $cmd
        echo "hypr-recover: da bat lai $name"
    fi
done

echo "hypr-recover: xong"
