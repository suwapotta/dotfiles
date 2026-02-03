# Arch Install Setup

<!--toc:start-->

- [Arch Install Setup](#arch-install-setup)
  - [Notes](#notes)
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
  - [Main installation](#main-installation)
    - [Select mirrors](#select-mirrors)
    - [Package Installation](#package-installation)
    - [Fstab](#fstab)
    - [Chroot](#chroot)
    - [Timezone](#timezone)
    - [Localization](#localization)
    - [Hostname](#hostname)
    - [Users](#users)
    - [Grub](#grub)
    - [Reboot](#reboot)
  - [Post-installation](#post-installation)
    - [AUR Helper](#aur-helper)
    - [Snapper](#snapper)
  - [Tips and Tricks](#tips-and-tricks)
    - [Snapper Recovery](#snapper-recovery)
  - [TODO](#todo)
  <!--toc:end-->

## Notes

This guide is meant to test within a virtual machine first, so it may not
match the real installation environment. The **main focus** of this guide
is to have an Arch setup that uses _snapper_ as an alternative to _timeshift_,
and also to quickly setup new machine as quick as possible.

For virtual machine, enable **UEFI** and **3D acceleration**.

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
# path_to_iso_directory
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
ping -c 3 ping.archlinux.org
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
# Check the disk directories/properties by using either
fdisk -l
# or
lsblk

# Start partitioning by
cfdisk /dev/nvme0n1 # TUI
# or
fdisk /dev/nvme0n1 # Terminal
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

> [!IMPORTANT]
>
> | Subvolume  | Mountpoint  |
> | ---------- | ----------- |
> | @          | /           |
> | @home      | /home       |
> | @var_log   | /var/log    |
> | @snapshots | /.snapshots |

```zsh
# Preparing
mount /dev/nvme0n1p3 /mnt

# Create subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@snapshots

# Unmount the root fs
umount /mnt
mount -o compress=zstd,subvol=@ /dev/nvme0n1p3 /mnt

# Apply Zstd compression + EFI
mkdir -p /mnt/{home,var/log,.snapshots,efi}
mount -o compress=zstd,subvol=@home /dev/nvme0n1p3 /mnt/home
mount -o compress=zstd,subvol=@var_log /dev/nvme0n1p3 /mnt/var/log
mount -o compress=zstd,subvol=@snapshots /dev/nvme0n1p3 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/efi

# Enable SWAP
swapon /dev/nvme0n1p2
```

## Main installation

### Select mirrors

This file will later be copied to the new system by `pacstrap`,
so it is worth getting right.

```zsh
# Install package
pacman -Sy reflector

# This may takes a while with 200 mirrors
reflector --latest 200 --verbose --sort rate --save /etc/pacman.d/mirrorlist

## Resync servers
pacman -Syyy
```

### Package Installation

```zsh
# "base linux linux-firmware" REQUIRED
# "man sudo" essentials
# "sof-firmware" onboard audio (e.g., IEM)
# "openssh" allow ssh and manage keys
# "base-devel" 'makepkg -si'
# "git" git stuffs
# "bluez bluez-utils" bluetooth
# "intel-ucode" microcode updates for gpu
# "networkmanager" manage internet connection for both wire and wireless
# "reflector" manages mirrorlist
# "btrfs-progs" file system management
# "efibootmgr" require for grub
# "grub" bootloader
# "grub-btrfs" btrfs support and snapshot boot menu
# "inotify-tools" watch for changes (snapshot)
# "pipewire pipewire-alsa pipewire-pulse pipewire-jack" audio framework
# "wireplumber" pipewire session manager
# "vim neovim" text editor

pacstrap -K /mnt 'packages'
```

### Fstab

```zsh
# Fetch the disk mounting points as they are now and generate instructions
# to let the system know how to mount the various disks automatically
genfstab -U /mnt >> /mnt/etc/fstab

# Check if fstab is fine
cat /mnt/etc/fstab
```

### Chroot

```zsh
# To access to our new system, we chroot into it
arch-chroot /mnt
```

### Timezone

```bash
# Add a symlink to local time
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

# Now sync the system time to hardware clock
hwclock --systohc

# Check time
date
```

### Localization

To use the correct region and language specific formatting
(like dates, currency, decimal separators), uncomment locales you will be using.

```bash
# I will uncomment the following:
# en_US.UTF-8 UTF-8
# vi_VN UTF-8
# ja_JP.UTF-8 UTF-8
nvim /etc/locale.gen

# Generate locales by running:
locale-gen
```

Set the locale to the desired one:

```bash
touch /etc/locale.conf
vim /etc/locale.conf
# Add: LANG=en_US.UTF-8
```

If you set the console keyboard layout, make the changes persistent in `/etc/vconsole.conf`:

```txt
KEYMAP=en
```

Check the output (after reboot only):

```bash
localectl status
# System Locale: LANG=en_US.UTF-8
#     VC Keymap: en
```

### Hostname

```bash
# Create /etc/hostname then choose and write the name of pc (Arch in my case)
touch /etc/hostname
nvim /etc/hostname

# Create the /etc/hosts file. This is very important because it will resolve the
# listed hostnames locally and not over Internet DNS.
touch /etc/hosts
nvim /etc/host

# Change the content to match:
# 127.0.0.1 localhost
# ::1 localhost
# 127.0.1.1 Arch
```

### Users

```bash
# Setup root password
passwd

# Add user
# -m creates the home directory automatically
# -G adds the user to the administration group wheel
useradd -mG wheel <username>
passwd <username>

# Uncomment line below this line to allow user to have "superuser" permission
# > Uncomment to let members of group wheel execute any action"
EDITOR=nvim visudo
```

### Grub

Install grub and its configuration into system:

```bash
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

### Reboot

```bash
# For internet connection
systemctl enable NetworkManager

# Exit from chroot
exit

# Safety measure
umount -R /mnt

# Reboot and unplug the installation media
reboot
```

## Post-installation

### Network Manager

[NetworkManager](https://wiki.archlinux.org/title/NetworkManager)
ships a text user interface
(TUI) for managing connections, the system host name
and radio switches. But there also is `nmcli` if feeling spicy.

```bash
nmtui
```

### AUR Helper

My personal choice is `paru`:

```bash
sudo pacman -S --needed base-devel

mkdir -p ~/Downloads/Repositories/
cd ~/Downloads/Repositories/
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

### Snapper

```bash
# Switch to root user if not already
su

# Install essential packages
pacman -S snapper snap-pac

# Avoid conflicting with previous sub-volume for next step
umount /.snapshots
rm -rf /.snapshots

# Start creating snapper configuration
snapper -c root create-config /
nvim /etc/snapper/configs/root
### Edit the following:
# ALLOW_USER="" -> Add username
# Change the limit for timeline cleanup at the end of file

# Visible for normal users
chmod a+rx /.snapshots

# Enable startup these services
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service
```

Basically, Arch is now ready for use. If so, congrats!

## Tips and Tricks

### Snapper Recovery

This allows us to restore a snapper snapshot even if the system is bricked.
Start with booting into an **Arch live environment**, and execute the following:

```bash
mount /dev/nvme0n1p3 /mnt
vim /mnt/@snapshots/*/info.xml
# ":bn" and ":bp" to navigate between buffers

rm -rf /mnt/@
# Replace 1 with desired snapshot
btrfs subvolume snapshot /mnt/@snapshots/1/snapshot /mnt/@
reboot
```

## TODO

- **fcitx5** and Catpuccin theme
- **MControlCenter**
- **reflector** configuration
- **systemd**: enable bluetooth.service + reflector.timer
- **paru**
- **install.sh**: for dotfiles:
  - Additional packages: "rg zoxide fzf fd yazi tmux lazygit sddm niri unzip"
  - AUR: "zen-browser-bin noctalia-shell"
- **NVIDIA drivers** :(
- **lazygit** setup
- **QEMU** VMs
