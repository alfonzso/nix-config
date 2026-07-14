#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
C0R3_ANYWHERE_DIR="$(realpath "$SCRIPT_DIR/..")"
WS="$(realpath "$C0R3_ANYWHERE_DIR/../..")"

# Alpine installer ISO.
ALPINE_VERSION="${ALPINE_VERSION:-3.22}"
ALPINE_RELEASE="${ALPINE_RELEASE:-3.22.2}"
ALPINE_FLAVOR="${ALPINE_FLAVOR:-standard}"
ARCH="${ARCH:-x86_64}"
ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"

OUT_DIR="${OUT_DIR:-$WS/var/installer}"
ISO_NAME="alpine-${ALPINE_FLAVOR}-${ALPINE_RELEASE}-${ARCH}.iso"
ISO_URL="${ISO_URL:-$ALPINE_MIRROR/v${ALPINE_VERSION}/releases/${ARCH}/${ISO_NAME}}"
ISO_IN="${ISO_IN:-$OUT_DIR/$ISO_NAME}"
ISO="${ISO:-$OUT_DIR/nixos-anywhere-alpine-${ALPINE_RELEASE}-${ARCH}.iso}"

EXTRA_PKGS="${EXTRA_PKGS:-openssh kexec-tools rsync e2fsprogs util-linux bash ca-certificates}"
EXTRA_CA_BUNDLE="${EXTRA_CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}"
KERNEL_CMDLINE_EXTRA="${KERNEL_CMDLINE_EXTRA:-kexec_load_disabled=0}"

# SSH keys authorized inside the live installer.
SSH_PUBKEY="${SSH_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"
AUTHORIZED_KEYS="${AUTHORIZED_KEYS:-}"

# VM / disks.
VM_DIR="${VM_DIR:-$WS/var/vm/c0r3}"
SSD_IMAGE="${SSD_IMAGE:-$VM_DIR/ssd.qcow2}"
HDD_IMAGE="${HDD_IMAGE:-$VM_DIR/hdd.qcow2}"
SSD_SIZE="${SSD_SIZE:-500G}"
HDD_SIZE="${HDD_SIZE:-1T}"

SSH_KEY="${SSH_KEY:-$VM_DIR/id_ed25519}"
SSH_PORT="${SSH_PORT:-2222}"

# nixos-anywhere / QEMU.
TARGET="${TARGET:-test-c0r3}"
KEXEC_EXTRA_FLAGS="${KEXEC_EXTRA_FLAGS:---kexec-syscall-auto}"
MEMORY="${MEMORY:-6144}"
CPUS="${CPUS:-8}"
QEMU_DISPLAY="${QEMU_DISPLAY:-gtk}"
EXTRA_PUBKEY="${EXTRA_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"
REBUILD_ISO="${REBUILD_ISO:-1}"

require_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || {
      echo "Missing required command: $c" >&2
      exit 1
    }
  done
}

find_sops_key() {
  local candidate
  for candidate in \
    "/home/${USER}/.config/sops/age/keys.txt" \
    "/persist/sops/age/keys.txt" \
    "/persists/sops/age/keys.txt"; do
    [[ -f "$candidate" ]] && {
      printf '%s\n' "$candidate"
      return
    }
  done
  echo "Cannot find sops age key (checked ~/.config, /persist, /persists)." >&2
  exit 1
}

find_xorriso() {
  if [[ -n "${XORRISO:-}" && -x "${XORRISO}" ]]; then
    echo "$XORRISO"
    return
  fi

  local out
  for out in $(nix build --no-link --print-out-paths nixpkgs#xorriso); do
    [[ -x "$out/bin/xorriso" ]] && {
      echo "$out/bin/xorriso"
      return
    }
  done

  echo "Could not find the xorriso binary." >&2
  exit 1
}

setup_ovmf() {
  local vars_target="$1" mode="$2"
  local ovmf_out ovmf_vars_template

  ovmf_out="${OVMF_OUT:-$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)}"
  ovmf_code="${OVMF_CODE:-$ovmf_out/FV/OVMF_CODE.fd}"
  ovmf_vars_template="${OVMF_VARS_TEMPLATE:-$ovmf_out/FV/OVMF_VARS.fd}"
  ovmf_vars="$vars_target"

  if [[ ! -f "$ovmf_code" || ! -f "$ovmf_vars_template" ]]; then
    echo "Could not find OVMF firmware under: $ovmf_out" >&2
    exit 1
  fi

  if [[ "$mode" == "fresh" || ! -e "$ovmf_vars" ]]; then
    cp -f "$ovmf_vars_template" "$ovmf_vars"
    chmod u+w "$ovmf_vars"
  fi
}

qemu_flags() {
  accel_args=()
  [[ -r /dev/kvm && -w /dev/kvm ]] && accel_args=(-enable-kvm)

  if [[ "$QEMU_DISPLAY" == "nographic" ]]; then
    display_args=(-nographic)
  else
    display_args=(-display "$QEMU_DISPLAY")
  fi
}

installer_authorized_keys() {
  local keys=""

  if [[ -n "$AUTHORIZED_KEYS" ]]; then
    [[ -f "$AUTHORIZED_KEYS" ]] || {
      echo "AUTHORIZED_KEYS file not found: $AUTHORIZED_KEYS" >&2
      exit 1
    }
    keys="$(<"$AUTHORIZED_KEYS")"
  elif [[ -f "$SSH_PUBKEY" ]]; then
    keys="$(<"$SSH_PUBKEY")"
  else
    echo "No SSH public key found. Set SSH_PUBKEY=/path/key.pub or AUTHORIZED_KEYS=/path/keys" >&2
    exit 1
  fi

  keys="$(printf '%s\n' "$keys" | grep -vE '^\s*(#|$)' || true)"
  [[ -n "$keys" ]] || {
    echo "No usable SSH public keys after filtering." >&2
    exit 1
  }

  printf '%s\n' "$keys"
}

write_installer_bootstrap() {
  local bootstrap="$1"

  cat >"$bootstrap" <<EOF
#!/bin/sh
exec >>/var/log/nixos-anywhere-bootstrap.log 2>&1
set -x

cat >/etc/apk/repositories <<REPOS
${ALPINE_MIRROR}/v${ALPINE_VERSION}/main
${ALPINE_MIRROR}/v${ALPINE_VERSION}/community
REPOS

for iface in /sys/class/net/*; do
  name=\$(basename "\$iface")
  [ "\$name" = "lo" ] && continue
  ip link set "\$name" up 2>/dev/null || true
  udhcpc -i "\$name" -b -q 2>/dev/null || true
done

i=0
while [ \$i -lt 30 ]; do
  if apk update; then break; fi
  i=\$((i + 1))
  sleep 2
done
apk add ${EXTRA_PKGS}
update-ca-certificates
if [ -f /etc/ssl/host-ca-bundle.crt ]; then
  cat /etc/ssl/host-ca-bundle.crt >>/etc/ssl/certs/ca-certificates.crt
  ln -sf certs/ca-certificates.crt /etc/ssl/cert.pem
fi

mkdir -p /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys 2>/dev/null || true

if [ -f /etc/ssh/sshd_config ]; then
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

rc-update add sshd default 2>/dev/null || true
rc-service sshd restart 2>/dev/null || rc-service sshd start 2>/dev/null || true
EOF

  chmod +x "$bootstrap"
}

cmd_build_iso() {
  require_cmd curl tar nix

  local keys xorriso_bin work ovl apkovl cfg
  keys="$(installer_authorized_keys)"
  xorriso_bin="$(find_xorriso)"

  mkdir -p "$OUT_DIR"
  if [[ ! -f "$ISO_IN" ]]; then
    echo "Downloading Alpine ISO:"
    echo "  $ISO_URL"
    curl -L --fail --output "$ISO_IN" "$ISO_URL"
  fi

  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN

  ovl="$work/ovl"
  mkdir -p \
    "$ovl/etc/local.d" \
    "$ovl/etc/runlevels/sysinit" \
    "$ovl/etc/runlevels/boot" \
    "$ovl/etc/runlevels/default" \
    "$ovl/etc/ssl" \
    "$ovl/root/.ssh"

  printf '# Live installer runs in RAM; no persistent mounts.\n' >"$ovl/etc/fstab"
  printf '%s\n' "$keys" >"$ovl/root/.ssh/authorized_keys"

  if [[ -n "$EXTRA_CA_BUNDLE" && -f "$EXTRA_CA_BUNDLE" ]]; then
    cp "$EXTRA_CA_BUNDLE" "$ovl/etc/ssl/host-ca-bundle.crt"
  fi

  # Applying an apkovl can skip these early services; re-add them explicitly.
  ln -sf /etc/init.d/modloop "$ovl/etc/runlevels/sysinit/modloop"
  ln -sf /etc/init.d/hwdrivers "$ovl/etc/runlevels/sysinit/hwdrivers"
  ln -sf /etc/init.d/local "$ovl/etc/runlevels/default/local"

  write_installer_bootstrap "$ovl/etc/local.d/nixos-anywhere.start"

  apkovl="$work/localhost.apkovl.tar.gz"
  tar --owner=0 --group=0 -czf "$apkovl" -C "$ovl" .

  cfg="$work/cfg"
  mkdir -p "$cfg"
  "$xorriso_bin" -osirrox on -indev "$ISO_IN" \
    -extract /boot/grub/grub.cfg "$cfg/grub.cfg" \
    -extract /boot/syslinux/syslinux.cfg "$cfg/syslinux.cfg"

  local map_args=(-map "$apkovl" /localhost.apkovl.tar.gz)
  if [[ -n "$KERNEL_CMDLINE_EXTRA" ]]; then
    sed -i -E "s@^([[:space:]]*linux[[:space:]]+/boot/vmlinuz[^\n]*)@\1 ${KERNEL_CMDLINE_EXTRA}@" "$cfg/grub.cfg"
    sed -i -E "s@^([[:space:]]*APPEND[[:space:]]+[^\n]*)@\1 ${KERNEL_CMDLINE_EXTRA}@I" "$cfg/syslinux.cfg"
    map_args+=(-map "$cfg/grub.cfg" /boot/grub/grub.cfg)
    map_args+=(-map "$cfg/syslinux.cfg" /boot/syslinux/syslinux.cfg)
  fi

  echo "Remastering ISO -> $ISO"
  rm -f "$ISO"
  "$xorriso_bin" -indev "$ISO_IN" -outdev "$ISO" "${map_args[@]}" -boot_image any replay

  echo
  echo "Done."
  echo "  Base ISO : $ISO_IN"
  echo "  Output   : $ISO"
  echo
  echo "Boot a machine from it (needs DHCP), then run:"
  echo "  make -C scripts/c0r3-anywhere nx-any-installer"
  echo "  nix run github:numtide/nixos-anywhere -- --flake .#<host> --phases kexec,disko,install root@<ip>"
}

cmd_start_qemu() {
  require_cmd nix qemu-img qemu-system-x86_64 ssh-keygen
  mkdir -p "$VM_DIR"

  [[ -e "$SSH_KEY" ]] || ssh-keygen -t ed25519 -N "" -C "c0r3-test-vm" -f "$SSH_KEY"

  if [[ "$REBUILD_ISO" == "1" || ! -f "$ISO" ]]; then
    local keys_file
    keys_file="$(mktemp)"
    trap 'rm -f "$keys_file"' RETURN

    cat "$SSH_KEY.pub" >"$keys_file"
    [[ -f "$EXTRA_PUBKEY" ]] && cat "$EXTRA_PUBKEY" >>"$keys_file"

    echo "Building installer ISO with VM key authorized..."
    AUTHORIZED_KEYS="$keys_file" cmd_build_iso
  fi

  [[ -f "$ISO" ]] || {
    echo "Installer ISO not found: $ISO" >&2
    exit 1
  }

  [[ -e "$SSD_IMAGE" ]] || qemu-img create -f qcow2 "$SSD_IMAGE" "$SSD_SIZE"
  [[ -e "$HDD_IMAGE" ]] || qemu-img create -f qcow2 "$HDD_IMAGE" "$HDD_SIZE"

  setup_ovmf "$VM_DIR/OVMF_VARS.iso-test.fd" fresh
  qemu_flags

  echo "Installer ISO: $ISO"
  echo "  SSD: $SSD_IMAGE ($SSD_SIZE, serial c0r3-test-ssd)"
  echo "  HDD: $HDD_IMAGE ($HDD_SIZE, serial c0r3-test-hdd)"
  echo "SSH forward: localhost:$SSH_PORT -> guest:22 (root, key: $SSH_KEY)"
  echo "When Alpine is up, run:  make -C scripts/c0r3-anywhere nx-any-installer"

  exec qemu-system-x86_64 \
    "${accel_args[@]}" \
    -machine q35 -m "$MEMORY" -smp "$CPUS" \
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
}

cmd_nx_any_installer() {
  require_cmd nix ssh rsync

  local phase="${1:-install}" phases host keys_src extra_files
  case "$phase" in
    disko) phases="${PHASES:-kexec,disko}" ;;
    install) phases="${PHASES:-kexec,disko,install}" ;;
    *)
      echo "Unknown phase: $phase (use install|disko)" >&2
      exit 1
      ;;
  esac

  host="${SSH_HOST:-root@127.0.0.1}"

  if [[ ! -f "$SSH_KEY" ]]; then
    echo "Missing VM SSH private key: $SSH_KEY" >&2
    echo "Run 'make -C scripts/c0r3-anywhere start-qemu' first to create it." >&2
    exit 1
  fi

  if ! ssh -i "$SSH_KEY" -p "$SSH_PORT" "$host" -- uptime >/dev/null; then
    echo "Cannot reach the VM: $host on port $SSH_PORT" >&2
    exit 1
  fi

  keys_src="$(find_sops_key)"
  extra_files="$(mktemp -d)"
  trap 'rm -rf "$extra_files"' RETURN
  rsync -avz --mkpath "$keys_src" "$extra_files/persist/sops/age/"

  cd "$WS"
  nix run github:numtide/nixos-anywhere -- \
    --flake ".#$TARGET" \
    --phases "$phases" \
    --kexec-extra-flags "$KEXEC_EXTRA_FLAGS" \
    -i "$SSH_KEY" \
    --ssh-option "Port=$SSH_PORT" \
    --extra-files "$extra_files" \
    "$host"
}

cmd_start_installed() {
  require_cmd nix qemu-system-x86_64

  if [[ ! -e "$SSD_IMAGE" ]]; then
    echo "SSD image not found: $SSD_IMAGE" >&2
    echo "Run 'make -C scripts/c0r3-anywhere start-qemu' + 'make -C scripts/c0r3-anywhere nx-any-installer' first." >&2
    exit 1
  fi

  mkdir -p "$VM_DIR"
  setup_ovmf "$VM_DIR/OVMF_VARS.installed.fd" persist
  qemu_flags

  echo "Booting installed NixOS from SSD:"
  echo "  SSD: $SSD_IMAGE (serial c0r3-test-ssd)"
  echo "  HDD: $HDD_IMAGE (serial c0r3-test-hdd)"
  echo "SSH forward: localhost:$SSH_PORT -> guest:22"

  exec qemu-system-x86_64 \
    "${accel_args[@]}" \
    -machine q35 -m "$MEMORY" -smp "$CPUS" \
    -drive if=pflash,format=raw,readonly=on,file="$ovmf_code" \
    -drive if=pflash,format=raw,file="$ovmf_vars" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
    -device virtio-net-pci,netdev=net0 \
    -drive "file=$SSD_IMAGE,if=none,id=ssd,format=qcow2,discard=unmap" \
    -device virtio-blk-pci,drive=ssd,serial=c0r3-test-ssd,bootindex=0 \
    -drive "file=$HDD_IMAGE,if=none,id=hdd,format=qcow2,discard=unmap" \
    -device virtio-blk-pci,drive=hdd,serial=c0r3-test-hdd \
    "${display_args[@]}"
}

cmd_help() {
  cat <<EOF
Usage: make -C scripts/c0r3-anywhere <target>

Targets:
  build-iso                    Build the bootable Alpine installer ISO
  start-qemu                   Build ISO if needed, then boot QEMU installer
  nx-any-installer             Run nixos-anywhere against the booted VM
  nx-any-installer PHASE=disko Run nixos-anywhere kexec+disko only
  nx-any-installer-disko       Alias for PHASE=disko
  start-installed              Boot the installed system from the SSD

Common env/config:
  SSH_PORT=$SSH_PORT MEMORY=$MEMORY CPUS=$CPUS QEMU_DISPLAY=$QEMU_DISPLAY
  TARGET=$TARGET REBUILD_ISO=$REBUILD_ISO
EOF
}

case "${1:-help}" in
  build-iso) cmd_build_iso ;;
  start-qemu) cmd_start_qemu ;;
  nx-any-installer) shift; cmd_nx_any_installer "${1:-install}" ;;
  start-installed) cmd_start_installed ;;
  help | -h | --help) cmd_help ;;
  *)
    echo "Unknown command: $1" >&2
    echo >&2
    cmd_help >&2
    exit 1
    ;;
esac
