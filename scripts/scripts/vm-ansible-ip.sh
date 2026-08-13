#!/usr/bin/env bash
# Lấy IP của ansible test VM và tạo inventory file
export LIBVIRT_DEFAULT_URI="qemu:///system"

VM_NAME="ansible-ubuntu-test"
ANSIBLE_REPO="${HOME}/work/goline/vgaia/vgaia-system-setup-bis"

STATE=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "not found")
if [ "$STATE" != "running" ]; then
  echo "VM '$VM_NAME' không chạy (state: $STATE)"
  echo "Chạy: vm-ansible-create"
  exit 1
fi

IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

if [ -z "$IP" ]; then
  echo "Chưa có IP. VM vẫn đang boot, thử lại sau 10s..."
  sleep 10
  IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
fi

if [ -z "$IP" ]; then
  echo "Vẫn chưa có IP. Thử: virsh domifaddr $VM_NAME"
  exit 1
fi

echo "VM IP: $IP"
echo ""
echo "Test SSH:  ssh bisadm@$IP"
echo ""
echo "Test Ansible ping:"
echo "  cd $ANSIBLE_REPO/ansible"
echo "  ansible -i inventories/local/hosts.yml all -m ping"
echo ""

# Tạo/cập nhật inventory file
INVENTORY_DIR="${ANSIBLE_REPO}/ansible/inventories/local"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.yml"

mkdir -p "$INVENTORY_DIR"
cat > "$INVENTORY_FILE" << EOF
all:
  children:
    docker_manager:
      hosts:
        manager1:
          ansible_host: ${IP}
          ansible_user: bisadm
          app_labels:
            - app
            - traefik
            - core-app
            - maxscale
            - kafka1
            - mariadb-master
            - middleware
            - middware
            - sentinel1
            - redis
            - keycloak1

    docker_worker:
      hosts:
        worker1:
          ansible_host: ${IP}
          ansible_user: bisadm
          app_labels:
            - app
            - kafka2
            - mariadb-slave1
            - middleware
            - middware
            - sentinel2
            - redis
            - market-app

    middleware:
      hosts:
        middleware1:
          ansible_host: ${IP}
          ansible_user: bisadm

    nfs-server:
      hosts:
        nfs1:
          ansible_host: ${IP}
          ansible_user: bisadm
EOF

echo "Inventory đã ghi: $INVENTORY_FILE"
