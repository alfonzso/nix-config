# c0r3 Install Notes

This host is a Windows 10 dual-boot install. Windows stays on the existing
system disk and keeps its own EFI partition. NixOS gets a separate EFI
partition, plus `/` on the system disk and `/nix` + `/games` on the 1TB disk.

## Target Layout

System disk:

- Existing Windows partitions: keep untouched.
- New NixOS EFI partition: 512M-1G, FAT32, mounted at `/boot`.
- New NixOS root partition: ext4, mounted at `/`.

1TB disk:

- `/nix`: 300G ext4.
- `/games`: remaining space ext4.

Boot selection:

- Use the motherboard boot menu, probably `F12`, to choose between `NixOS` and
  `Windows Boot Manager`.
- The existing Windows EFI partition should not be formatted or mounted as
  `/boot` for this install.

## Before Booting the NixOS ISO

In Windows:

1. Back up anything important.
2. Disable Windows fast startup/hibernation.
3. Shrink the C: partition using Windows Disk Management.
4. Leave the new space unformatted.
5. Keep the existing Windows EFI partition untouched.

## In the NixOS Live ISO

Identify disks and partitions:

```bash
lsblk -f
ls -l /dev/disk/by-id/
```

Find:

- The 1TB disk by-id path for `CHANGE-ME-c0r3-1tb-disk`.
- The new NixOS root partition UUID for `CHANGE-ME-c0r3-root`.
- The new NixOS EFI partition UUID for `CHANGE-ME-c0r3-nixos-efi`.

Update these files in the repo:

- `nx/hosts/c0r3/modules/disko.nix`
- `nx/hosts/c0r3/hardware-configuration.nix`

## Create the Manual System Partitions

Recommended: use GParted from the live ISO. It is easier to visually confirm
that you are editing the free space after Windows C: and not the Windows EFI or
Windows data partition.

In GParted, select the system disk and create these partitions in the
unallocated space made by shrinking C::

- NixOS EFI: 512M-1G, FAT32.
- NixOS root: ext4, remaining desired Linux system space.

For the NixOS EFI partition, set the `esp` and `boot` flags if GParted offers
them. Give the partitions clear labels if you want, for example `NIXOS_EFI` and
`NIXOS_ROOT`.

If you use GParted to format them, you do not need to run `mkfs` manually.
Afterward, check UUIDs:

```bash
lsblk -f
```

CLI fallback, only if you are sure about the disk and partition names:

```bash
parted /dev/disk/by-id/<system-disk> -- mkpart NIXOS_EFI fat32 <efi-start> <efi-end>
parted /dev/disk/by-id/<system-disk> -- set <efi-partition-number> esp on
parted /dev/disk/by-id/<system-disk> -- mkpart NIXOS_ROOT ext4 <root-start> 100%
```

If you used the CLI fallback instead of GParted formatting, format the new
partitions, replacing device names with the real partition paths:

```bash
mkfs.vfat -F 32 /dev/disk/by-id/<nixos-efi-partition>
mkfs.ext4 /dev/disk/by-id/<nixos-root-partition>
```

Do not format the Windows EFI partition. Do not run these commands against C:.

## Prepare the 1TB Disk

After replacing `CHANGE-ME-c0r3-1tb-disk`, run:

```bash
bash scripts/run_c0r3.sh disko
```

This runs only the disko phase. It will wipe the configured 1TB disk and create
`/nix` and `/games`. It should not touch the Windows/system disk.

## Mount for Install

Mount the prepared filesystems on the live ISO:

```bash
mount /dev/disk/by-uuid/<c0r3-root-uuid> /mnt
mkdir -p /mnt/boot /mnt/nix /mnt/games
mount /dev/disk/by-uuid/<c0r3-nixos-efi-uuid> /mnt/boot
mount /dev/disk/by-uuid/<c0r3-nix-uuid> /mnt/nix
mount /dev/disk/by-uuid/<c0r3-games-uuid> /mnt/games
```

Use `lsblk -f` after the disko step to find the `/nix` and `/games` UUIDs.

## Install with nixos-anywhere

After all `CHANGE-ME-c0r3` placeholders are replaced and `/mnt` is mounted:

```bash
bash scripts/run_c0r3.sh install
```

If the live ISO SSH host is different:

```bash
SSH_HOST=admin@<live-iso-host> bash scripts/run_c0r3.sh install
```

The script runs nixos-anywhere with `PHASES=install`, so it expects the mount
layout to already exist.

## After Install

Reboot and choose the boot entry:

- `NixOS` for Linux.
- `Windows Boot Manager` for Windows.

If the firmware does not default to the one you want, change the boot order in
UEFI setup. Windows remains available from the firmware boot menu.
