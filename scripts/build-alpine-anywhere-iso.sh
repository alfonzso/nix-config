#!/usr/bin/env bash
set -euo pipefail

# Build a small bootable Alpine live ISO that comes up (in RAM, diskless) with:
#   - DHCP networking
#   - sshd enabled, root login by SSH key only (your key pre-seeded)
#   - kexec-tools + the bits nixos-anywhere needs on the "kexec-from" host
#
# It does NOT install anything to disk. You boot a machine from it, then from
# your workstation run:
#   nixos-anywhere --flake .#<host> --phases kexec,disko,install root@<ip>
#
# Implementation: an official Alpine ISO is remastered with an apkovl overlay
# (localhost.apkovl.tar.gz) placed at the ISO root. Alpine's diskless init
# auto-loads any *.apkovl.tar.gz found on the boot media.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
WS="$(realpath "$DIR/..")"

ALPINE_VERSION="${ALPINE_VERSION:-3.22}"     # branch, used for apk repositories
ALPINE_RELEASE="${ALPINE_RELEASE:-3.22.2}"   # full release for the ISO download
ALPINE_FLAVOR="${ALPINE_FLAVOR:-standard}"   # standard (bare metal) or virt (VM)
ARCH="${ARCH:-x86_64}"

ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"
ISO_NAME="alpine-${ALPINE_FLAVOR}-${ALPINE_RELEASE}-${ARCH}.iso"
ISO_URL="${ISO_URL:-$ALPINE_MIRROR/v${ALPINE_VERSION}/releases/${ARCH}/${ISO_NAME}}"

OUT_DIR="${OUT_DIR:-$WS/var/installer}"
ISO_IN="${ISO_IN:-$OUT_DIR/$ISO_NAME}"
ISO_OUT="${ISO_OUT:-$OUT_DIR/nixos-anywhere-alpine-${ALPINE_RELEASE}-${ARCH}.iso}"

# Packages installed on first boot (needs network at boot).
EXTRA_PKGS="${EXTRA_PKGS:-openssh kexec-tools rsync e2fsprogs util-linux bash}"

# Extra kernel cmdline params baked into the ISO boot config.
# kexec_load_disabled=0 is REQUIRED: Alpine kernels are hardened and the
# kexec_load syscall defaults to disabled (kernel.kexec_load_disabled=1), which
# cannot be turned off at runtime. Without it nixos-anywhere's kexec phase fails
# with "kexec_load failed: Operation not permitted".
KERNEL_CMDLINE_EXTRA="${KERNEL_CMDLINE_EXTRA:-kexec_load_disabled=0}"

# SSH public key(s) authorized for root on the live installer.
#   SSH_PUBKEY       - path to a single .pub file (default: ~/.ssh/id_ed25519.pub)
#   AUTHORIZED_KEYS  - path to a file with one or more keys (overrides SSH_PUBKEY)
SSH_PUBKEY="${SSH_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"
AUTHORIZED_KEYS="${AUTHORIZED_KEYS:-}"

usage() {
  cat <<EOF
Usage:
  $0
  SSH_PUBKEY=~/.ssh/id_ed25519.pub $0
  AUTHORIZED_KEYS=/path/to/keys $0
  ALPINE_FLAVOR=virt $0

Environment (current defaults):
  ALPINE_VERSION=$ALPINE_VERSION
  ALPINE_RELEASE=$ALPINE_RELEASE
  ALPINE_FLAVOR=$ALPINE_FLAVOR   (standard = bare metal, virt = VM)
  ARCH=$ARCH
  ISO_URL=$ISO_URL
  OUT_DIR=$OUT_DIR
  ISO_OUT=$ISO_OUT
  EXTRA_PKGS=$EXTRA_PKGS
  SSH_PUBKEY=$SSH_PUBKEY
  AUTHORIZED_KEYS=$AUTHORIZED_KEYS

Output:
  A bootable ISO at \$ISO_OUT. Boot a machine from it; it gets a DHCP lease,
  installs kexec-tools + ssh, and lets root log in with your key. Then run:

    nixos-anywhere --flake .#<host> --phases kexec,disko,install root@<ip>
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

require_cmd curl
require_cmd tar
require_cmd nix

# Collect authorized keys.
keys=""
if [[ -n "$AUTHORIZED_KEYS" ]]; then
  if [[ ! -f "$AUTHORIZED_KEYS" ]]; then
    echo "AUTHORIZED_KEYS file not found: $AUTHORIZED_KEYS" >&2
    exit 1
  fi
  keys="$(cat "$AUTHORIZED_KEYS")"
elif [[ -f "$SSH_PUBKEY" ]]; then
  keys="$(cat "$SSH_PUBKEY")"
else
  echo "No SSH public key found." >&2
  echo "Set SSH_PUBKEY=/path/to/key.pub or AUTHORIZED_KEYS=/path/to/keys" >&2
  echo "Or create one with: ssh-keygen -t ed25519" >&2
  exit 1
fi

# Strip blank/comment lines so we do not feed junk to authorized_keys.
keys="$(printf '%s\n' "$keys" | grep -vE '^\s*(#|$)' || true)"
if [[ -z "$keys" ]]; then
  echo "No usable SSH public keys after filtering." >&2
  exit 1
fi

# Locate xorriso (used to remaster the ISO in place, keeping BIOS+UEFI boot).
xorriso_bin="${XORRISO:-}"
if [[ -z "$xorriso_bin" ]]; then
  for out in $(nix build --no-link --print-out-paths nixpkgs#xorriso); do
    if [[ -x "$out/bin/xorriso" ]]; then
      xorriso_bin="$out/bin/xorriso"
      break
    fi
  done
fi
if [[ -z "$xorriso_bin" || ! -x "$xorriso_bin" ]]; then
  echo "Could not find the xorriso binary." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

if [[ ! -f "$ISO_IN" ]]; then
  echo "Downloading Alpine ISO:"
  echo "  $ISO_URL"
  curl -L --fail --output "$ISO_IN" "$ISO_URL"
fi

work="$(mktemp -d)"
cleanup() { rm -rf "$work"; }
trap cleanup EXIT

ovl="$work/ovl"
mkdir -p \
  "$ovl/etc/local.d" \
  "$ovl/etc/runlevels/sysinit" \
  "$ovl/etc/runlevels/boot" \
  "$ovl/etc/runlevels/default" \
  "$ovl/root/.ssh"

# etc/fstab must exist for the overlay to be applied by the diskless init.
cat >"$ovl/etc/fstab" <<'EOF'
# Live installer runs in RAM; no persistent mounts.
EOF

# Root's authorized keys.
printf '%s\n' "$keys" >"$ovl/root/.ssh/authorized_keys"

# When an apkovl overlay is applied, Alpine's diskless init no longer wires up
# the modloop service automatically, which leaves /lib/modules unmounted and no
# kernel modules (incl. network drivers) available. Re-add it so modules load.
ln -sf /etc/init.d/modloop "$ovl/etc/runlevels/sysinit/modloop"

# Bring standard early services back too, so networking modules/hotplug work.
ln -sf /etc/init.d/hwdrivers "$ovl/etc/runlevels/sysinit/hwdrivers"

# Enable the "local" service so our first-boot script runs.
ln -sf /etc/init.d/local "$ovl/etc/runlevels/default/local"

# First-boot bootstrap: network up, install packages, start sshd for root key login.
cat >"$ovl/etc/local.d/nixos-anywhere.start" <<EOF
#!/bin/sh
# Bring the box up ready for nixos-anywhere. Logs to /var/log/nixos-anywhere-bootstrap.log
exec >>/var/log/nixos-anywhere-bootstrap.log 2>&1
set -x

# Point apk at the online mirror (the diskless boot repo is the read-only CD).
cat >/etc/apk/repositories <<REPOS
${ALPINE_MIRROR}/v${ALPINE_VERSION}/main
${ALPINE_MIRROR}/v${ALPINE_VERSION}/community
REPOS

# Bring up every wired interface via DHCP (udhcpc also writes /etc/resolv.conf).
for iface in /sys/class/net/*; do
  name=\$(basename "\$iface")
  [ "\$name" = "lo" ] && continue
  ip link set "\$name" up 2>/dev/null || true
  udhcpc -i "\$name" -b -q 2>/dev/null || true
done

# Wait until DNS/network is usable, then install what nixos-anywhere needs.
i=0
while [ \$i -lt 30 ]; do
  if apk update; then
    break
  fi
  i=\$((i + 1))
  sleep 2
done
apk add ${EXTRA_PKGS}

# Root SSH key was placed by the overlay; lock down permissions.
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys 2>/dev/null || true

# Key-only root login.
if [ -f /etc/ssh/sshd_config ]; then
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

rc-update add sshd default 2>/dev/null || true
rc-service sshd restart 2>/dev/null || rc-service sshd start 2>/dev/null || true
EOF
chmod +x "$ovl/etc/local.d/nixos-anywhere.start"

# Pack the overlay. Name prefix is irrelevant when it is the only apkovl on the
# media, but "localhost" matches the ISO's default hostname.
apkovl="$work/localhost.apkovl.tar.gz"
tar --owner=0 --group=0 -czf "$apkovl" -C "$ovl" .

# Patch the boot configs to append the extra kernel cmdline (kexec_load_disabled=0).
# grub.cfg is used for UEFI boot, syslinux.cfg for legacy BIOS boot.
cfg="$work/cfg"
mkdir -p "$cfg"
"$xorriso_bin" -osirrox on -indev "$ISO_IN" \
  -extract /boot/grub/grub.cfg "$cfg/grub.cfg" \
  -extract /boot/syslinux/syslinux.cfg "$cfg/syslinux.cfg"

map_args=(-map "$apkovl" /localhost.apkovl.tar.gz)
if [[ -n "$KERNEL_CMDLINE_EXTRA" ]]; then
  # UEFI (grub): append to the "linux /boot/vmlinuz-lts ..." line.
  sed -i -E "s@^([[:space:]]*linux[[:space:]]+/boot/vmlinuz[^\n]*)@\1 ${KERNEL_CMDLINE_EXTRA}@" "$cfg/grub.cfg"
  # BIOS (syslinux): append to the "APPEND ..." line.
  sed -i -E "s@^([[:space:]]*APPEND[[:space:]]+[^\n]*)@\1 ${KERNEL_CMDLINE_EXTRA}@I" "$cfg/syslinux.cfg"
  map_args+=(-map "$cfg/grub.cfg" /boot/grub/grub.cfg)
  map_args+=(-map "$cfg/syslinux.cfg" /boot/syslinux/syslinux.cfg)
fi

echo "Remastering ISO -> $ISO_OUT"
rm -f "$ISO_OUT"
"$xorriso_bin" \
  -indev "$ISO_IN" \
  -outdev "$ISO_OUT" \
  "${map_args[@]}" \
  -boot_image any replay

echo
echo "Done."
echo "  Base ISO : $ISO_IN"
echo "  Output   : $ISO_OUT"
echo
echo "Boot a machine from it (needs DHCP/network), then from $WS run e.g.:"
echo "  nix run github:numtide/nixos-anywhere -- \\"
echo "    --flake .#<host> --phases kexec,disko,install root@<ip>"
