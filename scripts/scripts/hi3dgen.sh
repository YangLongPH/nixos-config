#!/usr/bin/env bash
# Manage Hi3DGen API server

CMD="${1:-status}"

case "$CMD" in
    start)
        sudo systemctl start hi3dgen-api
        echo "Hi3DGen starting... run 'hi3dgen logs' to follow"
        ;;
    stop)
        sudo systemctl stop hi3dgen-api
        ;;
    restart)
        sudo systemctl restart hi3dgen-api
        ;;
    enable)
        sudo systemctl enable --now hi3dgen-api
        echo "Hi3DGen enabled and started (will auto-start on boot)"
        ;;
    disable)
        sudo systemctl disable --now hi3dgen-api
        ;;
    status)
        systemctl status hi3dgen-api --no-pager
        ;;
    logs)
        journalctl -u hi3dgen-api -f
        ;;
    *)
        echo "Usage: hi3dgen [start|stop|restart|enable|disable|status|logs]"
        ;;
esac
