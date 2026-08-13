#!/usr/bin/env bash
# Tạo Ubuntu 22.04 VM để test Ansible từ NixOS host
set -euo pipefail

export LIBVIRT_DEFAULT_URI="qemu:///system"

VM_NAME="ansible-ubuntu-test"
VM_RAM=2048
VM_VCPUS=2
VM_DISK_SIZE=40

IMAGES_DIR="${HOME}/vm-images"
CLOUD_IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
CLOUD_IMAGE="${IMAGES_DIR}/ubuntu-22.04-cloudimg-base.qcow2"
VM_DISK="${IMAGES_DIR}/${VM_NAME}.qcow2"
SEED_ISO="${IMAGES_DIR}/${VM_NAME}-seed.iso"
SSH_KEY="$(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null)"

if [ -z "$SSH_KEY" ]; then
  echo "ERROR: Không tìm thấy SSH public key (~/.ssh/id_ed25519.pub)"
  exit 1
fi

mkdir -p "$IMAGES_DIR"

# Kiểm tra VM đã tồn tại chưa
if virsh domstate "$VM_NAME" &>/dev/null; then
  echo "VM '$VM_NAME' đã tồn tại."
  virsh domstate "$VM_NAME"
  echo "Dùng 'virsh start $VM_NAME' để bật, hoặc 'vm-ansible-ip' để xem IP."
  exit 0
fi

# Đảm bảo default network đang chạy
NET_STATE=$(virsh net-info default 2>/dev/null | grep '^Active:' | awk '{print $2}')
if [ "$NET_STATE" != "yes" ]; then
  echo "Khởi động default network..."
  virsh net-autostart default
  virsh net-start default
fi

# Download Ubuntu cloud image nếu chưa có
if [ ! -f "$CLOUD_IMAGE" ]; then
  echo "Downloading Ubuntu 22.04 cloud image (~600MB)..."
  wget -O "$CLOUD_IMAGE" "$CLOUD_IMAGE_URL"
fi

# Tạo disk VM (copy-on-write từ base image, không sửa base)
echo "Tạo VM disk ${VM_DISK_SIZE}GB..."
qemu-img create -f qcow2 -b "$CLOUD_IMAGE" -F qcow2 "$VM_DISK" "${VM_DISK_SIZE}G"

# Tạo cloud-init user-data
USER_DATA=$(mktemp)
cat > "$USER_DATA" << EOF
#cloud-config
hostname: ansible-test
users:
  - name: bisadm
    groups: [sudo]
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${SSH_KEY}
package_update: false
packages:
  - python3
  - openssh-server
runcmd:
  - systemctl enable ssh
  - systemctl start ssh
EOF

META_DATA=$(mktemp)
cat > "$META_DATA" << EOF
instance-id: ${VM_NAME}
local-hostname: ansible-test
EOF

# Tạo cloud-init seed ISO
echo "Tạo cloud-init seed ISO..."
cloud-localds "$SEED_ISO" "$USER_DATA" "$META_DATA"
rm "$USER_DATA" "$META_DATA"

# Tạo và khởi động VM
echo "Tạo VM '$VM_NAME'..."
virt-install \
  --name "$VM_NAME" \
  --ram "$VM_RAM" \
  --vcpus "$VM_VCPUS" \
  --disk "path=${VM_DISK},format=qcow2" \
  --disk "path=${SEED_ISO},device=cdrom" \
  --os-variant ubuntu22.04 \
  --network network=default \
  --graphics none \
  --import \
  --noautoconsole \
  --noreboot

virsh start "$VM_NAME"

echo ""
echo "VM '$VM_NAME' đã tạo và đang khởi động."
echo "Chờ 40s để VM boot và lấy IP..."
sleep 40

vm-ansible-ip
