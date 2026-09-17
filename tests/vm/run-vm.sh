#!/usr/bin/env bash
# run-vm.sh — launch kome test VM (Arch cloud image + cloud-init).

set -euo pipefail

IMG_URL="https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
IMG_FILE="/var/lib/libvirt/images/arch-cloud.qcow2"
SEED_ISO="/tmp/kome-seed.iso"
SSH_PORT=2222

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --img FILE      Use local qcow2 image (default: download latest Arch cloud)
  --port N        SSH port forward (default: 2222)
  --keep          Keep VM running after test
  -h              Show help
EOF
}

KEEP=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --img) IMG_FILE="$2"; shift 2 ;;
        --port) SSH_PORT="$2"; shift 2 ;;
        --keep) KEEP=1; shift ;;
        -h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

if [[ ! -f "$IMG_FILE" ]]; then
    echo "Downloading Arch cloud image..."
    curl -L "$IMG_URL" -o "$IMG_FILE"
fi

# create cloud-init seed ISO
mkdir -p /tmp/kome-seed
cat > /tmp/kome-seed/user-data <<'EOF'
#cloud-config
users:
  - name: kome
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    passwd: "$6$rounds=4096$kome$dummy"
runcmd:
  - su - kome -c "git clone https://github.com/Joey-1123/kome-dots.git /home/kome/kome"
  - su - kome -c "cd /home/kome/kome && ./install.sh --yes --profile standard --skip-system"
power_state:
  mode: reboot
EOF

cat > /tmp/kome-seed/meta-data <<'EOF'
instance-id: kome-test
local-hostname: kome-vm
EOF

genisoimage -output "$SEED_ISO" -volid cidata -joliet -rock /tmp/kome-seed/user-data /tmp/kome-seed/meta-data

echo "Starting VM on port $SSH_PORT..."
qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -smp 2 \
    -drive file="$IMG_FILE",format=qcow2,if=virtio \
    -drive file="$SEED_ISO",format=raw,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::$SSH_PORT-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic \
    -name kome-test

if [[ "$KEEP" != "1" ]]; then
    rm -f "$SEED_ISO"
    rm -rf /tmp/kome-seed
fi