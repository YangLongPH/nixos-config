#!/usr/bin/env bash
# Manage TRELLIS API server

CMD="${1:-status}"

case "$CMD" in
    start)
        sudo systemctl start trellis-api
        echo "TRELLIS starting... run 'trellis logs' to follow"
        ;;
    stop)
        sudo systemctl stop trellis-api
        ;;
    restart)
        sudo systemctl restart trellis-api
        ;;
    enable)
        sudo systemctl enable --now trellis-api
        echo "TRELLIS enabled and started (will auto-start on boot)"
        ;;
    disable)
        sudo systemctl disable --now trellis-api
        ;;
    status)
        systemctl status trellis-api --no-pager
        ;;
    logs)
        journalctl -u trellis-api -f
        ;;
    *)
        echo "Usage: trellis [start|stop|restart|enable|disable|status|logs]"
        ;;
esac
