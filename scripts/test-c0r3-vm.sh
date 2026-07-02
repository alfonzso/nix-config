#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
WS="$(realpath "$DIR/..")"

VM_DIR="${VM_DIR:-$WS/var/vm/c0r3}"
BOOTSTRAP_BASE_URL="${BOOTSTRAP_BASE_URL:-https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/cloud/nocloud_alpine-3.22.2-x86_64-uefi-tiny-r0.qcow2}"
BOOTSTRAP_BASE_IMAGE="${BOOTSTRAP_BASE_IMAGE:-$VM_DIR/$(basename "$BOOTSTRAP_BASE_URL")}"
BOOTSTRAP_IMAGE="${BOOTSTRAP_IMAGE:-$VM_DIR/bootstrap.qcow2}"
BOOTSTRAP_SIZE="${BOOTSTRAP_SIZE:-8G}"
SEED_ISO="${SEED_ISO:-$VM_DIR/seed.iso}"
SSD_IMAGE="${SSD_IMAGE:-$VM_DIR/ssd.qcow2}"
HDD_IMAGE="${HDD_IMAGE:-$VM_DIR/hdd.qcow2}"
SSH_KEY="${SSH_KEY:-$VM_DIR/id_ed25519}"
SSD_SIZE="${SSD_SIZE:-500G}"
HDD_SIZE="${HDD_SIZE:-1T}"
SSH_PORT="${SSH_PORT:-2222}"
MEMORY="${MEMORY:-8192}"
CPUS="${CPUS:-4}"
SSH_PUBKEY="${SSH_PUBKEY:-$SSH_KEY.pub}"
QEMU_DISPLAY="${QEMU_DISPLAY:-gtk}"

usage() {
  cat <<EOF
Usage:
  $0
  BOOTSTRAP_BASE_IMAGE=/path/to/alpine-cloud.qcow2 $0

Environment:
  VM_DIR=$VM_DIR
  BOOTSTRAP_BASE_URL=$BOOTSTRAP_BASE_URL
  BOOTSTRAP_BASE_IMAGE=$BOOTSTRAP_BASE_IMAGE
  BOOTSTRAP_IMAGE=$BOOTSTRAP_IMAGE
  BOOTSTRAP_SIZE=$BOOTSTRAP_SIZE
  SEED_ISO=$SEED_ISO
  SSD_IMAGE=$SSD_IMAGE
  HDD_IMAGE=$HDD_IMAGE
  SSH_KEY=$SSH_KEY
  SSD_SIZE=$SSD_SIZE
  HDD_SIZE=$HDD_SIZE
  SSH_PORT=$SSH_PORT
  MEMORY=$MEMORY
  CPUS=$CPUS
  SSH_PUBKEY=$SSH_PUBKEY
  QEMU_DISPLAY=$QEMU_DISPLAY

The qcow2 disks are sparse/dynamic. They advertise large sizes to the guest
but only consume host storage as data is written.

Default bootstrap image is Alpine NoCloud cloud image. This script creates a
NoCloud seed ISO with your SSH key, then boots the cloud image plus c0r3 test
SSD/HDD install targets.

Then from the host run, once Alpine finishes booting:
  SSH_HOST=root@127.0.0.1 SSH_PORT=$SSH_PORT scripts/run_test_c0r3.sh install
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd nix
require_cmd qemu-img
require_cmd qemu-system-x86_64
require_cmd curl
require_cmd ssh-keygen

mkdir -p "$VM_DIR"

if [[ ! -e "$SSH_KEY" ]]; then
  ssh-keygen -t ed25519 -N "" -C "c0r3-test-vm" -f "$SSH_KEY"
fi

if [[ ! -e "$BOOTSTRAP_BASE_IMAGE" ]]; then
  echo "Downloading Alpine cloud image:"
  echo "  $BOOTSTRAP_BASE_URL"
  curl -L --fail --output "$BOOTSTRAP_BASE_IMAGE" "$BOOTSTRAP_BASE_URL"
fi

if [[ ! -e "$BOOTSTRAP_IMAGE" ]]; then
  qemu-img create -f qcow2 -F qcow2 -b "$BOOTSTRAP_BASE_IMAGE" "$BOOTSTRAP_IMAGE"
fi
qemu-img resize "$BOOTSTRAP_IMAGE" "$BOOTSTRAP_SIZE" >/dev/null

if [[ -n "$SSH_PUBKEY" ]]; then
  if [[ ! -f "$SSH_PUBKEY" ]]; then
    echo "SSH_PUBKEY does not exist: $SSH_PUBKEY" >&2
    exit 1
  fi
  ssh_key="$(cat "$SSH_PUBKEY")"
elif compgen -G "$HOME/.ssh/*.pub" >/dev/null; then
  ssh_key="$(cat "$HOME"/.ssh/*.pub)"
else
  echo "No SSH public keys found in $HOME/.ssh/*.pub" >&2
  echo "Create one with: ssh-keygen -t ed25519" >&2
  echo "Or rerun with: SSH_PUBKEY=/path/to/key.pub $0" >&2
  exit 1
fi

seed_dir="$(mktemp -d)"
cleanup_seed() {
  rm -rf "$seed_dir"
}
trap cleanup_seed EXIT

cat >"$seed_dir/meta-data" <<EOF
instance-id: c0r3-test
local-hostname: c0r3-test-bootstrap
public-keys:
$(printf '%s\n' "$ssh_key" | sed 's/^/  - /')
EOF

cat >"$seed_dir/user-data" <<EOF
#!/bin/sh
set -eu

mkdir -p /root/.ssh /home/alpine/.ssh
cat >/root/.ssh/authorized_keys <<'KEYS'
$ssh_key
KEYS
cat >/home/alpine/.ssh/authorized_keys <<'KEYS'
$ssh_key
KEYS
chmod 700 /root/.ssh /home/alpine/.ssh
chmod 600 /root/.ssh/authorized_keys /home/alpine/.ssh/authorized_keys
chown -R alpine:alpine /home/alpine/.ssh

apk update
apk add bash openssh kexec-tools tar util-linux rsync doas e2fsprogs-extra

adduser alpine wheel || true
echo 'permit nopass :wheel' >/etc/doas.d/wheel.conf

passwd -u root || true
passwd -u alpine || true

sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
rc-update add sshd default || true
rc-service sshd restart || true
EOF

xorriso="$(
  for output in $(nix build --no-link --print-out-paths nixpkgs#xorriso); do
    if [[ -x "$output/bin/xorrisofs" ]]; then
      printf '%s\n' "$output/bin/xorrisofs"
      break
    fi
  done
)"
if [[ -z "$xorriso" ]]; then
  echo "Could not find xorrisofs in nixpkgs#xorriso outputs." >&2
  exit 1
fi
"$xorriso" -quiet -volid cidata -joliet -rock -output "$SEED_ISO" "$seed_dir"

if [[ ! -e "$SSD_IMAGE" ]]; then
  qemu-img create -f qcow2 "$SSD_IMAGE" "$SSD_SIZE"
fi

if [[ ! -e "$HDD_IMAGE" ]]; then
  qemu-img create -f qcow2 "$HDD_IMAGE" "$HDD_SIZE"
fi

ovmf_out="${OVMF_OUT:-$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)}"
ovmf_code="${OVMF_CODE:-$ovmf_out/FV/OVMF_CODE.fd}"
ovmf_vars_template="${OVMF_VARS_TEMPLATE:-$ovmf_out/FV/OVMF_VARS.fd}"
ovmf_vars="$VM_DIR/OVMF_VARS.fd"

if [[ ! -f "$ovmf_code" || ! -f "$ovmf_vars_template" ]]; then
  echo "Could not find OVMF firmware under: $ovmf_out" >&2
  exit 1
fi

if [[ ! -e "$ovmf_vars" ]]; then
  cp "$ovmf_vars_template" "$ovmf_vars"
  chmod u+w "$ovmf_vars"
fi

accel_args=()
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  accel_args=(-enable-kvm)
fi

display_args=()
if [[ "$QEMU_DISPLAY" == "nographic" ]]; then
  display_args=(-nographic)
else
  display_args=(-display "$QEMU_DISPLAY")
fi

echo "VM disks:"
echo "  Bootstrap: $BOOTSTRAP_IMAGE"
echo "  SSD: $SSD_IMAGE ($SSD_SIZE, serial c0r3-test-ssd)"
echo "  HDD: $HDD_IMAGE ($HDD_SIZE, serial c0r3-test-hdd)"
echo "NoCloud seed ISO: $SEED_ISO"
echo "SSH forward: localhost:$SSH_PORT -> guest:22"

exec qemu-system-x86_64 \
  "${accel_args[@]}" \
  -machine q35 \
  -m "$MEMORY" \
  -smp "$CPUS" \
  -drive if=pflash,format=raw,readonly=on,file="$ovmf_code" \
  -drive if=pflash,format=raw,file="$ovmf_vars" \
  -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
  -device virtio-net-pci,netdev=net0 \
  -drive "file=$BOOTSTRAP_IMAGE,if=none,id=bootstrap,format=qcow2,discard=unmap" \
  -device virtio-blk-pci,drive=bootstrap,serial=c0r3-test-bootstrap \
  -drive "file=$SEED_ISO,if=none,id=seed,format=raw,readonly=on,media=cdrom" \
  -device ide-cd,drive=seed \
  -drive "file=$SSD_IMAGE,if=none,id=ssd,format=qcow2,discard=unmap" \
  -device virtio-blk-pci,drive=ssd,serial=c0r3-test-ssd \
  -drive "file=$HDD_IMAGE,if=none,id=hdd,format=qcow2,discard=unmap" \
  -device virtio-blk-pci,drive=hdd,serial=c0r3-test-hdd \
  "${display_args[@]}"
