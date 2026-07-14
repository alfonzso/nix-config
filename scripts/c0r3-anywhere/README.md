# c0r3-anywhere

Make targets backed by `lib/c0r3-anywhere.sh` to build a small bootable
**Alpine installer ISO**, install a NixOS host onto it with
[`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere), and boot the
result, both in a local QEMU VM and (for the ISO) on real hardware.

Default target: the `test-c0r3` flake config (which reuses `future-c0r3`).

## Targets

```bash
make -C scripts/c0r3-anywhere build-iso                    # build the Alpine installer ISO only
make -C scripts/c0r3-anywhere start-qemu                   # build ISO if needed + boot it in QEMU
make -C scripts/c0r3-anywhere nx-any-installer             # nixos-anywhere onto the booted VM
make -C scripts/c0r3-anywhere nx-any-installer PHASE=disko # kexec+disko only
make -C scripts/c0r3-anywhere start-installed              # boot the installed system from the SSD
```

## VM workflow

```bash
# Terminal 1 — build the ISO (if needed) and boot it in QEMU with the test disks
make -C scripts/c0r3-anywhere start-qemu

# Terminal 2 — once Alpine is up, install NixOS onto the disks
make -C scripts/c0r3-anywhere nx-any-installer             # kexec,disko,install
make -C scripts/c0r3-anywhere nx-any-installer PHASE=disko # kexec,disko only

# When it finishes, stop the ISO VM, then boot the result
make -C scripts/c0r3-anywhere start-installed
```

## What each target does

- **build-iso** — remasters the official Alpine ISO into
  `var/installer/nixos-anywhere-alpine-<rel>-<arch>.iso`: injects an `apkovl`
  overlay (first boot: DHCP, `apk add kexec-tools/rsync/...`, drop your SSH key
  for `root`, start `sshd`) and bakes `kexec_load_disabled=0` into the boot
  cmdline (required, or `nixos-anywhere`'s kexec fails on Alpine).
  Keys: `SSH_PUBKEY` (default `~/.ssh/id_ed25519.pub`) or `AUTHORIZED_KEYS`.
  Flavor: `ALPINE_FLAVOR=standard` (bare metal) or `virt` (VM only).

- **start-qemu** — the combined "build + start the VM" command. (Re)builds the ISO
  authorizing the VM key (`var/vm/c0r3/id_ed25519`) + your personal key, creates
  the sparse test disks, and boots QEMU (UEFI/OVMF) from the ISO with:
  - SSD `ssd.qcow2` (serial `c0r3-test-ssd`) → `/boot`, `/`, `/home`
  - HDD `hdd.qcow2` (serial `c0r3-test-hdd`) → `/games`
  Disks are matched **by serial** in disko, so ordering doesn't matter.
  SSH is forwarded `localhost:2222 -> guest:22`. It only starts the VM — the
  actual install happens in the separate `nx-any-installer` step. `REBUILD_ISO=0` reuses
  an existing ISO instead of remastering.

- **nx-any-installer** — runs `nixos-anywhere --flake .#test-c0r3` against the booted VM
  (`root@127.0.0.1:2222`, VM key), copying the sops age key via `--extra-files`.
  The ISO is Alpine (not NixOS), so the `kexec` phase is always included.
  Self-contained (no external wrapper). Override with `PHASES=...`.

- **start-installed** — boots the *installed* system from the SSD (no ISO), `virtio-blk`,
  UEFI/OVMF. Log in as `alfonzso` on the console or `ssh -p 2222 alfonzso@127.0.0.1`.
  The test host forces `console=ttyS0`, so `QEMU_DISPLAY=nographic` (serial) is
  the easiest way in; the graphical KDE session has no real GPU in QEMU.

## Bare metal

`make -C scripts/c0r3-anywhere build-iso`, then `dd if=<iso> of=/dev/sdX bs=4M oflag=sync`, boot the target
(needs DHCP), find its IP, and run
`nix run github:numtide/nixos-anywhere -- --flake .#<host> --phases kexec,disko,install root@<ip>`.

## Prerequisites

`nix`, `qemu` (`qemu-system-x86_64`, `qemu-img`), `curl`, `ssh`, `ssh-keygen`,
`rsync`, and a sops age key at `~/.config/sops/age/keys.txt` (or `/persist/...`).
KVM is used automatically when available.

## Fixes baked into the flow (for reference)

- ISO boots with `kexec_load_disabled=0` (Alpine kernels disable `kexec_load`).
- The installed initrd includes `virtio_blk` + `ext4` (`tests/hosts/c0r3/default.nix`)
  so it can boot from the QEMU disks.
- `/home` is `neededForBoot` (`future-c0r3`'s disko module) so activation-time
  writes into the user's home (sops `~/.ssh`, rclone config, ...) land on the
  real `/home` instead of being shadowed by the later mount.
- Artifacts live under `var/installer/` and `var/vm/c0r3/` (git-ignored).
