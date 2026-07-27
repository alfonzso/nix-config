# `busa` machine inventory and NixOS migration

> **Donor-disk inventory only:** the Toshiba/Debian machine described below is
> not the new NixOS target. The `busanas` host targets a Dell Latitude 5400
> (UEFI, Intel Core i5-8365U, 8 GiB RAM, Intel UHD 620), using its NVMe for
> NixOS and repurposing this donor SSD as `/srv/media` only after backup.

Inventory taken on 2026-07-27 from the current Debian installation. This is a
migration checklist, not a ready-to-deploy hardware configuration.

## Executive summary

This machine needs a new, independent host configuration. Do not reuse or
modify an existing host merely because its name happens to match this
machine's current Debian hostname.

Create a fresh hardware configuration and storage plan for this physical
machine before the first NixOS install.

## Machine map

### Platform and hardware

- Current OS: Debian GNU/Linux 12 (bookworm)
- Current hostname omitted to avoid conflating this machine with an existing
  repository host
- Architecture: `x86_64-linux`
- Firmware boot mode: legacy BIOS, not UEFI
- Laptop: Toshiba, firmware 1.50
- CPU: Intel Pentium B940, 2 cores at 2.00 GHz
- RAM: 2.7 GiB
- Swap: 976 MiB
- Graphics: Intel 2nd-generation integrated graphics, `i915`
- Ethernet: Realtek RTL810xE, interface `enp2s0`, driver `r8169`
- Wi-Fi: Qualcomm Atheros AR9285, interface `wlp3s0`, driver `ath9k`
- Audio: Intel HDA, `snd_hda_intel`
- Other hardware: webcam, Realtek card reader, Bluetooth, optical drive
- Battery health is effectively failed: approximately 1.8% of design capacity
- Typical observed CPU temperature: 47–56 °C

This is a low-memory machine. Prefer a small service set and avoid enabling
libvirt/QEMU, GNOME, and other heavy services unless they are actually needed.

### Storage

Only one usable storage disk was detected:

| Device | Model | Size | Layout |
| --- | --- | ---: | --- |
| `/dev/sda` | Crucial BX500 SSD (`CT1000BX500SSD1`) | 931.5 GiB | MBR/BIOS, ext4 root plus swap |

Current filesystems:

- Root: `/dev/sda1`, ext4, UUID
  `a413827e-73fb-48d4-a940-1352b5a7c792`, about 144 GiB used
- Swap: `/dev/sda5`, UUID
  `b18446f4-e6d4-4d2b-b5c8-0b4ab7df8f8a`, 976 MiB
- No separate boot, home, or data filesystem
- No active NFS, CIFS, or mergerfs mount was detected

Important persistent data:

- `/home/busa/media`: about 135 GiB, currently exported by Samba
- `/home/busa/workdir`: source repositories and the Samba Compose project
- `/home/busa/.ssh`: SSH client configuration, authorized keys, and private
  keys
- Browser and desktop state under `/home/busa/.config`, `.local`, and
  `.mozilla`

Do not put media, browser profiles, private keys, or application state into the
Nix store. Back them up and restore them as mutable data.

### Network

- Network management: NetworkManager
- Active uplink: Wi-Fi with DHCP
- Ethernet is currently down
- Three saved Wi-Fi profiles and one wired profile exist
- Docker has its default bridge plus one Compose bridge
- IPv6 link-local addressing is active on Debian
- Locale: `en_US.UTF-8`
- Time zone: `Europe/Budapest`
- NTP synchronization: enabled

Wi-Fi credentials are in root-owned NetworkManager connection files. Move the
needed SSIDs/passwords to the existing SOPS Wi-Fi mechanism; do not commit the
connection files.

### Users and access

- Primary user: `busa`, UID/GID 1000, shell `/bin/bash`
- Important groups: `sudo`, `docker`, `audio`, `video`, `netdev`, `bluetooth`,
  `lpadmin`, and `scanner`
- SSH server is enabled
- Current SSH server configuration still relies mostly on Debian defaults;
  keyboard-interactive authentication is disabled
- `~/.ssh/authorized_keys` exists
- SSH client config contains a host alias and an identity file
- XRDP and LightDM are enabled
- User lingering is disabled

Migrate public/authorized keys declaratively. Put private keys and any key
passphrases in SOPS or restore them out-of-band with mode `0600`.

### Services

Enabled or currently relevant:

- OpenSSH
- Docker and containerd
- Samba in Docker Compose
- NetworkManager and `wpa_supplicant`
- XRDP
- LightDM
- CUPS and cups-browsed (no configured printer was detected)
- Avahi
- Bluetooth
- cron/anacron and standard maintenance timers
- PipeWire/WirePlumber user services

No custom cron entries or custom systemd service files were found. The host
firewall service is disabled; the complete live ruleset could not be inspected
without an interactive sudo password.

### Current Samba workload

Compose source: `/home/busa/workdir/samba/docker-compose.yaml`

- Image: `elswork/samba` (observed image version 4.18.9)
- One Samba container is currently running
- Restart policy: `always`
- Published TCP ports: 139 and 445
- Share source: `/home/busa/media`, mounted as `/media`
- Samba user/share arguments come from `/home/busa/workdir/samba/.env`
- Logs/state are bind-mounted from `/home/busa/workdir/samba/log`

The `.env` file was deliberately not read. Its credentials must be moved to
SOPS, not copied into this repository in plaintext.

Preserve `/home/busa/media` initially or deliberately migrate it to a new
storage layout. Do not assume that another host's Samba paths, users, or disk
pool apply to this machine.

### Desktop and applications

Both GNOME and XFCE are installed. XFCE configuration and panel plugins are
present, and GNOME sessions are also available. Transmission GTK, Google
Chrome, Vim, tmux, htop, Git, curl, compiler tools, and common network tools
are installed.

No Nix installation, Snap, Flatpak applications, pipx packages, global npm
packages, Rust toolchains, or Cargo-installed tools were detected.

For this hardware, choose one desktop. XFCE plus LightDM is the lighter match.
If the machine is intended to be a headless server, omit both desktops and
retain XRDP only if remote graphical access is genuinely required.

## What to add or change in `nix-config`

### 1. Replace the host hardware configuration

After booting the NixOS installer on this exact machine, regenerate:

```bash
nixos-generate-config --show-hardware-config
```

Use the result in a new host directory for this machine. Expected hardware
needs include `ata_piix`, `r8169`, `ath9k`, `i915`, Intel microcode, USB storage,
and legacy BIOS boot.

### 2. Design the disk migration explicitly

Choose one of these approaches:

1. Preserve the current ext4 layout and install without reformatting, after a
   tested backup.
2. Repartition the SSD with Disko. For legacy BIOS, include a BIOS boot
   partition and define root plus swap. This is destructive and requires a
   verified restore path for the 135 GiB media tree.

Use a stable `/dev/disk/by-id/...` path collected from the installer in the new
Disko configuration. Do not use `/dev/sda` as the long-term identifier.

### 3. Make host identity intentional

- Use a deliberate declarative username; `busa` preserves the current account.
- Preserve UID 1000 if restoring the existing home and media ownership.
- Set a unique hostname explicitly.
- Choose one consistent Samba user and group.

### 4. Import only the modules this host needs

Create a new host directory and import only its selected storage and service
modules. Keep its hardware, disks, identity, and service state independent from
all existing hosts.

The shared `_virtualisation.nix` enables Podman, libvirt, QEMU, virt-manager,
and SPICE. That does not reproduce the current Docker host and is unnecessarily
heavy for 2.7 GiB RAM. Add a small Docker-only module, or deliberately migrate
the Samba container to native `services.samba`.

### 5. Migrate Samba

Preferred end state: native `services.samba` with:

- The same effective shares and access restrictions as the current container
- Samba password sourced from SOPS
- Firewall restricted to the trusted LAN where practical
- Correct ownership and masks for restored media
- `wsdd`/Avahi only if client discovery is needed

Do not enable mergerfs until multiple data disks actually exist. With one disk,
export the real media path directly.

An interim Docker migration is acceptable: declare Docker, the Compose project
or an OCI container, bind mounts, ports, and restart policy in NixOS while
keeping credentials in SOPS.

### 6. Add network and remote access

- Enable NetworkManager.
- Add the required Wi-Fi secrets through `sops-nix`.
- Preserve DHCP unless a static address or DHCP reservation is chosen.
- Decide whether this host should retain IPv6.
- Enable OpenSSH and import authorized public keys.
- Apply the repository's hardened SSH settings after confirming key login.
- Configure `networking.firewall` for SSH and Samba; add XRDP only if retained.
- Consider `sshguard`, already present in the shared SSH module.

### 7. Select user environment and packages

Add only actively used packages to system or Home Manager configuration:

- Baseline: Git, Vim/Neovim, tmux, htop, curl, wget, lsof, DNS tools, ping,
  traceroute, rsync, and bash completion
- Optional desktop: XFCE, LightDM, PipeWire, Chrome/Chromium, Transmission GTK
- Hardware utilities: `lm_sensors`, SMART tools, PCI/USB tools
- Server utilities: Docker/Compose only if Samba remains containerized

Review `.bashrc`, `.profile`, Vim configuration, XFCE settings, Transmission
settings, and browser bookmarks/extensions before deciding what belongs in
Home Manager. Copy preferences, not caches or machine-generated state.

### 8. Back up and restore mutable state

Before installation, create and test a backup of:

- `/home/busa/media`
- `/home/busa/workdir`
- selected home configuration and browser data
- SSH private keys and authorized keys
- Samba Compose `.env` and any service credentials
- a package/service inventory and the current partition table

Restore media with UID/GID-aware tools such as `rsync -aHAX` and verify file
ownership before exposing the Samba share.

## Suggested implementation order

1. Back up and verify the 135 GiB media/data set.
2. Decide username, hostname, desktop/headless role, and native Samba vs Docker.
3. Boot the installer and capture hardware config plus stable disk by-id path.
4. Add the new host imports, identity, and storage layout.
5. Add NetworkManager, SOPS Wi-Fi, SSH keys, and firewall rules.
6. Add Samba and restore its credentials through SOPS.
7. Evaluate the flake and build the host in a VM where possible.
8. Install, restore mutable data, and validate SSH/Samba before retiring Debian.

## Validation checklist

- `nix flake check` succeeds.
- `nixos-rebuild build --flake .#busa` succeeds (or use the final unique host
  output name).
- The generated system boots in legacy BIOS mode.
- Root and swap resolve by UUID/by-id as intended.
- Wi-Fi reconnects after reboot without plaintext secrets in Git or the store.
- SSH key login works before password login is disabled.
- Firewall exposes only intended services.
- Samba clients can read/write with expected ownership and masks.
- `/home`/media ownership still maps to UID/GID 1000 where required.
- Docker/Podman/libvirt and desktop services are absent unless explicitly
  selected.
- Media and credential backups can be restored independently of NixOS.
