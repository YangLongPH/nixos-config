#!/usr/bin/env bash
# Manage Hunyuan3D API server

CMD="${1:-status}"

case "$CMD" in
    start)
        sudo systemctl start hunyuan3d-api
        echo "Hunyuan3D starting... run 'hunyuan3d logs' to follow"
        ;;
    stop)
        sudo systemctl stop hunyuan3d-api
        ;;
    restart)
        sudo systemctl restart hunyuan3d-api
        ;;
    enable)
        sudo systemctl enable --now hunyuan3d-api
        echo "Hunyuan3D enabled and started (will auto-start on boot)"
        ;;
    disable)
        sudo systemctl disable --now hunyuan3d-api
        ;;
    status)
        systemctl status hunyuan3d-api --no-pager
        ;;
    logs)
        journalctl -u hunyuan3d-api -f
        ;;
    *)
        echo "Usage: hunyuan3d [start|stop|restart|enable|disable|status|logs]"
        ;;
esac
