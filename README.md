# Arch Install Setup

<!--toc:start-->

- [Arch Install Setup](#arch-install-setup)
  - [Note](#note)
  - [References](#references)
  - [Pre-installation](#pre-installation)
    - [Get an installation image](#get-an-installation-image)
    - [Verify signature](#verify-signature)
    - [Boot into live environment](#boot-into-live-environment)
    - [Set keyboard layout](#set-keyboard-layout)
    - [Set console font (optional)](#set-console-font-optional)
    - [Verify boot mode](#verify-boot-mode)
    - [Internet connection](#internet-connection)
    - [Update system clock](#update-system-clock)
    - [Disk partitioning](#disk-partitioning)
    - [Disk formatting](#disk-formatting)
    - [Disk mounting](#disk-mounting)
  - [Main installation](#main-installation) - [Select mirrors](#select-mirrors)
  <!--toc:end-->

## Note

This guide is meant to test within a virtual machine first, so it may not
match the real installation environment. The **main focus** of this guide
is to have an Arch setup that uses _snapper_ as an alternative to _timeshift_,
and to also quickly new machine as quick as possible.

For virtual machine, enable **UEFI** and **3D acceleration** .

## References

- [Official Arch Linux Installation guide](https://wiki.archlinux.org/title/Installation_guide)
- [A modern, updated Installation guide](https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae#introduction)
- [How to install Arch Linux with BTRFS & Snapper](https://www.youtube.com/watch?v=sm_fuBeaOqE&list=LL&index=1)

## Pre-installation

### Get an installation image

Firstly, download the latest Arch `iso` (also `sig` for the next step) file
from official [download page](https://archlinux.org/download/) that
should be updated at the beginning of a month.

### Verify signature

From an existing Arch Linux installation, run:

```zsh
pacman-key -v archlinux-version-x86_64.iso.sig
```

### Boot into live environment

> [!NOTE]
> Remember to disable secure boot option just for safe.

Copy/move the `iso` file into USB (Ventoy) and enter the live environment.
The path for USB should be: `/run/media/$USER/Ventoy/`, and should be ejected
after the USB's LED stop blinking.

Example:

```zsh
cp ~/Downloads/iso/archlinux-2026.02.01-x86_64.iso /run/media/suwapotta/Ventoy/
```

### Set keyboard layout

```zsh
localectl list-keymaps
# Should have en in the list, or just directly use this command
loadkeys en
```

### Set console font (optional)

```zsh
# Console fonts are located in /usr/share/kbd/consolefonts/
set-font ter-132b
```

### Verify boot mode

Check that we are in UEFI mode:

```zsh
cat /sys/firmware/efi/fw_platform_size
# Expected output: 64 (or 32)
```

### Internet connection

For Ethernet, this literally plug and play. However, WiFi requires
extra steps through using [iwctl](https://wiki.archlinux.org/title/Iwd#iwctl) :

```zsh
iwctl
# Interactive prompt for iwd:
device list # In my case, it will be wlan0
station wlan0 scan
station wlan get-networks
staion wlan0 connect ...
# Ctrl+D or exit
```

Finally, check for connection:

```zsh
ping -c 5 ping.archlinux.org
```

### Update system clock

```zsh
# Check if ntp is active and if the time is right
timedatectl

# In case it's not active you can do
timedatectl set-ntp true
```

### Disk partitioning

Layout after this step should look:

| Partition | Type             | Size            |
| --------- | ---------------- | --------------- |
| 1         | EFI              | 1 GiB           |
| 2         | Linux Swap       | 4 GiB           |
| 3         | Linux Filesystem | Remaining space |

```zsh
# Check the disk name by using either
lsblk
# or
fdisk -l

# Start partitioning by
cfdisk /dev/nvme0n1 # TUI
# or
fdisk /dev/nvme0n1 # Plain text
```

### Disk formatting

```zsh
### Example:
# NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
# nvme0n1     259:0    0 476.9G  0 disk
# ├─nvme0n1p1 259:1    0     1G  0 part
# ├─nvme0n1p2 259:2    0     4G  0 part
# └─nvme0n1p3 259:3    0 471.9G  0 part

mkfs.fat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
mkfs.btrfs /dev/nvme0n1p3
```

### Disk mounting

```zsh
# Grant access
mount /dev/nvme0n1p3 /mnt

# Create subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots

# Unmount the root fs
umount /mnt

# Apply Zstd compression + EFI
mkdir -p /mnt/{home,var,.snapshots,efi}
mount -o compress=zstd,subvol=@ /dev/nvme0n1p3 /mnt
mount -o compress=zstd,subvol=@home /dev/nvme0n1p3 /mnt/home
mount -o compress=zstd,subvol=@var /dev/nvme0n1p3 /mnt/var
mount -o compress=zstd,subvol=@snapshots /dev/nvme0n1p3 /mnt/.snapshots
mount /dev/nvme0n1 /mnt/efi

# Enable SWAP
swapon /dev/nvme0n1p2
```

## Main installation

### Select mirrors

```zsh
# Install package
pacman -S reflector

# This may takes a while with 200 mirrors
reflector --latest 200 --verbose --sort rate --save /etc/pacman.d/mirrorlist

## Resync servers
pacman -Syyy
```
