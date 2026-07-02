#!/usr/bin/env bash
set -euo pipefail

# Boot the Alpine nixos-anywhere installer ISO in QEMU with the same 2-disk
# layout used for c0r3 testing (SSD + HDD, matched by virtio serial), so you can
# drive nixos-anywhere against it exactly like the cloud-image VM flow.
#
# The disks are referenced by serial in the disko config:
#   /dev/disk/by-id/virtio-c0r3-test-ssd   (install target: /, /boot, /home)
#   /dev/disk/by-id/virtio-c0r3-test-hdd   (/games)
#
# The ISO is (re)built here authorizing the VM SSH key so run_test_c0r3.sh can
# log in as root. Once Alpine has booted, from the host run:
#   SSH_HOST=root@127.0.0.1 SSH_PORT=2222 scripts/run_test_c0r3.sh install

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
WS="$(realpath "$DIR/..")"

VM_DIR="${VM_DIR:-$WS/var/vm/c0r3}"

ALPINE_RELEASE="${ALPINE_RELEASE:-3.22.2}"
ARCH="${ARCH:-x86_64}"
ISO="${ISO:-$WS/var/installer/nixos-anywhere-alpine-${ALPINE_RELEASE}-${ARCH}.iso}"
REBUILD_ISO="${REBUILD_ISO:-1}"

SSD_IMAGE="${SSD_IMAGE:-$VM_DIR/ssd.qcow2}"
HDD_IMAGE="${HDD_IMAGE:-$VM_DIR/hdd.qcow2}"
SSD_SIZE="${SSD_SIZE:-500G}"
HDD_SIZE="${HDD_SIZE:-1T}"

SSH_KEY="${SSH_KEY:-$VM_DIR/id_ed25519}"
SSH_PORT="${SSH_PORT:-2222}"
MEMORY="${MEMORY:-8192}"
CPUS="${CPUS:-4}"
QEMU_DISPLAY="${QEMU_DISPLAY:-gtk}"

# Extra public key(s) to authorize (besides the VM key). Defaults to your
# personal key if present so you can also ssh in directly.
EXTRA_PUBKEY="${EXTRA_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"

usage() {
  cat <<EOF
Usage:
  $0
  QEMU_DISPLAY=nographic $0

Environment:
  VM_DIR=$VM_DIR
  ISO=$ISO
  REBUILD_ISO=$REBUILD_ISO   (1 = always remaster the ISO before booting)
  SSD_IMAGE=$SSD_IMAGE ($SSD_SIZE, serial c0r3-test-ssd)
  HDD_IMAGE=$HDD_IMAGE ($HDD_SIZE, serial c0r3-test-hdd)
  SSH_KEY=$SSH_KEY
  SSH_PORT=$SSH_PORT
  MEMORY=$MEMORY
  CPUS=$CPUS
  QEMU_DISPLAY=$QEMU_DISPLAY
  EXTRA_PUBKEY=$EXTRA_PUBKEY

The qcow2 disks are sparse: they advertise large sizes to the guest but only
consume host storage as data is written. Disks are matched by virtio serial,
so device ordering does not matter.

Once Alpine has booted (it gets a DHCP lease, installs kexec-tools + sshd), run:
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
require_cmd ssh-keygen

mkdir -p "$VM_DIR"

# VM SSH key (same one run_test_c0r3.sh uses via -i).
if [[ ! -e "$SSH_KEY" ]]; then
  ssh-keygen -t ed25519 -N "" -C "c0r3-test-vm" -f "$SSH_KEY"
fi

# (Re)build the installer ISO authorizing the VM key (+ your personal key).
if [[ "$REBUILD_ISO" == "1" || ! -f "$ISO" ]]; then
  keys_file="$(mktemp)"
  cat "$SSH_KEY.pub" >"$keys_file"
  if [[ -f "$EXTRA_PUBKEY" ]]; then
    cat "$EXTRA_PUBKEY" >>"$keys_file"
  fi
  echo "Building installer ISO with VM key authorized..."
  AUTHORIZED_KEYS="$keys_file" ALPINE_RELEASE="$ALPINE_RELEASE" ARCH="$ARCH" \
    ISO_OUT="$ISO" "$DIR/build-alpine-anywhere-iso.sh"
  rm -f "$keys_file"
fi

if [[ ! -f "$ISO" ]]; then
  echo "Installer ISO not found: $ISO" >&2
  exit 1
fi

if [[ ! -e "$SSD_IMAGE" ]]; then
  qemu-img create -f qcow2 "$SSD_IMAGE" "$SSD_SIZE"
fi

if [[ ! -e "$HDD_IMAGE" ]]; then
  qemu-img create -f qcow2 "$HDD_IMAGE" "$HDD_SIZE"
fi

ovmf_out="${OVMF_OUT:-$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)}"
ovmf_code="${OVMF_CODE:-$ovmf_out/FV/OVMF_CODE.fd}"
ovmf_vars_template="${OVMF_VARS_TEMPLATE:-$ovmf_out/FV/OVMF_VARS.fd}"
ovmf_vars="$VM_DIR/OVMF_VARS.iso-test.fd"

if [[ ! -f "$ovmf_code" || ! -f "$ovmf_vars_template" ]]; then
  echo "Could not find OVMF firmware under: $ovmf_out" >&2
  exit 1
fi

# Fresh NVRAM each run so stale UEFI boot entries do not shadow the ISO.
cp -f "$ovmf_vars_template" "$ovmf_vars"
chmod u+w "$ovmf_vars"

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

echo "Installer ISO: $ISO"
echo "VM disks:"
echo "  SSD: $SSD_IMAGE ($SSD_SIZE, serial c0r3-test-ssd)"
echo "  HDD: $HDD_IMAGE ($HDD_SIZE, serial c0r3-test-hdd)"
echo "SSH forward: localhost:$SSH_PORT -> guest:22 (root, key: $SSH_KEY)"
echo
echo "When Alpine is up, run:"
echo "  SSH_HOST=root@127.0.0.1 SSH_PORT=$SSH_PORT scripts/run_test_c0r3.sh install"

exec qemu-system-x86_64 \
  "${accel_args[@]}" \
  -machine q35 \
  -m "$MEMORY" \
  -smp "$CPUS" \
  -drive if=pflash,format=raw,readonly=on,file="$ovmf_code" \
  -drive if=pflash,format=raw,file="$ovmf_vars" \
  -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
  -device virtio-net-pci,netdev=net0 \
  -drive "file=$ISO,if=none,id=installer,format=raw,readonly=on,media=cdrom" \
  -device ide-cd,drive=installer,bootindex=0 \
  -drive "file=$SSD_IMAGE,if=none,id=ssd,format=qcow2,discard=unmap" \
  -device virtio-blk-pci,drive=ssd,serial=c0r3-test-ssd \
  -drive "file=$HDD_IMAGE,if=none,id=hdd,format=qcow2,discard=unmap" \
  -device virtio-blk-pci,drive=hdd,serial=c0r3-test-hdd \
  "${display_args[@]}"
