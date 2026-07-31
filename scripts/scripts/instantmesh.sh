#!/usr/bin/env bash
# Manage InstantMesh API server

CMD="${1:-status}"

case "$CMD" in
    start)
        sudo systemctl start instantmesh-api
        echo "InstantMesh starting... run 'instantmesh logs' to follow"
        ;;
    stop)
        sudo systemctl stop instantmesh-api
        ;;
    restart)
        sudo systemctl restart instantmesh-api
        ;;
    enable)
        sudo systemctl enable --now instantmesh-api
        echo "InstantMesh enabled and started (will auto-start on boot)"
        ;;
    disable)
        sudo systemctl disable --now instantmesh-api
        ;;
    status)
        systemctl status instantmesh-api --no-pager
        ;;
    logs)
        journalctl -u instantmesh-api -f
        ;;
    *)
        echo "Usage: instantmesh [start|stop|restart|enable|disable|status|logs]"
        ;;
esac
