# Quick Arch Deploy
The script should perform most of the heavy lifting (or repeatable tasks) however there are tasks to be performed once to prepare the system.
This guide is prepared using Arch Installation Guide on [Arch Wiki](https://wiki.archlinux.org). This is quick one pager for reference only. For more details, refer Arch Wiki.

# Support
I'm still learning and may not always be able to help. In case you know or fix any problem, please feel free to fork and suggest changes as required. I'll be obliged to improve this script as we move along.

# Table of Contents
S.No. | File Name | Description
----- | --------- | -----------
01 | [Preparation](#preparation) | Quick guide to activities to be performed before running the scripts
02 | [Partition](#partition) | Preaparing the disk paritions
03 | [Installation](#installation) | Install Arch Linux before running the scripts

# Preparation

## Load the correct keyboard map
Run the below command to get the keymap names available
```bash
ls /usr/share/kbd/keymaps/**/*xx*.map.gz
```
xx is country code e.g us for USA, uk for UK, de for Germany

Run below command to set the correct keys. Don't need for US keyboard
```bash
loadkeys us
loadkeys uk
loadkeys de-latin1
```
de-latin1 is for Germany

## Connect to the internet
Check if your network interface is listed and enabled for internet
```bash
ip link
```

Verify network is working by `ping`-ing your favourite website
```bash
ping archlinux.org
```

If there is no network, check hardware connections and Wifi is not hard disabled (some devices have switch or external wifi dongle is removed). Check if network interface is not soft blocked using `rkfill` command
```bash
rfkill list
```

If network interface is blocked then unblock network adapter
```bash
rkfill unblock wifi
```

### Setup Wifi
Run command to launch interactive shell
```bash
iwctl
```

The command prompt should change to `[iwd]#`. Help is avaialble by typing `help` command. When done, press `ctrl+d` to quit. Auto-completion is enabled, therefore hit `Tab` key to auto-complete suggestion

#### Connect to network
Get list of your devices. We need this to command the correct device to perform the following activities
```bash
device list
```

Scan for networks
```bash
station <device> scan
```

The scanning might take sometime, depending on your network strength
```bash
station <device> get-networks
```

Now connect to the network. Enter the password on prompt
```bash
station <device> connect <SSID>
```

#### Get Connection information
Get details of wifi device
```bash
device <device> list
```

Check the connection state
```bash
station <device> list
```

Get list of known networks connected
```bash
known-networks list
```

#### Disconnect from network
If network is not stable or like to connect to other network
```bash
station <device> disconnect
```

Forget the known network
```bash
known-networks <SSID> forget
```

## Set System Time
Ensure System clock is accurate
```bash
timedatectl set-ntp true
```

[Back to contents](#table-of-contents)

# Partition

## Partition Hard Disk
Partition using `fdisk`, `gdisk` or any of your application of your choice. For EUFI, drive should have a GPT partition table. `/root` & `/boot` partitions are mandatory.

Suggested partition layout:
Partition | Size (Without Hibernation) | Size (With Hibernation)
--------- | ------------------------------ | ---------------------------
Boot | 512 MB | NA
Swap (RAM < 2 GB) | Same as RAM | RAM * 2
Swap (RAM >= 2 GB & < 4 GB) | Half of RAM | RAM + 2
Swap (RAM >= 4 GB & < 8 GB) | Half of RAM | Depending on load (> RAM)
Swap (RAM >= 8 GB) | Depending on load | Depending on load (> RAM)
Root (With home partition) | 25 GB | NA
Root (No home partition) | 50 GB | NA

## Mount partitions
Mount the root partition
```bash
mkfs.ext4 /dev/<root_partition> -L <label>
mount /dev/<root_partition> /mnt
```

Mount the EFI partition
```bash
mkfs.fat -F32 /dev/<efi_partition>
mkdir /mnt/boot
mount /dev/<efi_partition> /mnt/boot
```

If you've separate home partition, mount the home partition. The `home` directory would be automatically created in `/mnt` if a partition is not assigned
```bash
mkfs.ext4 /dev/<home_partition> -L <label>
mkdir /mnt/home
mount /dev/<home_partition> /mnt/home
```

Mount swap partition if created separately. The script will prompt to create a swapfile during install.
**Warning:** _Do not perform `mkswap` if you've existing swap partition being used._
```bash
mkswap /dev/<swap_partition>
swapon /dev/<swap_partition>
```

## Verify the mounted partitions
Use `findmnt` to identify the mounted paritions.

[Back to contents](#table-of-contents)

# Installation

## Install Arch Linux
Get latest mirrors and install the base package only
The command `reflector --list-countries` would get the county code which will be used as parameter to `-c` option for `reflector`. I've set it as `GB` for my purpose.

```bash
pacman -Syy reflector
reflector --list-countries | grep "GB"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector -c "GB" --age 12 --fastest 20 --latest 20 -n 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt base git nano
```
- You may use `vim` or `nano` or both as an editor

## Prepare the filesystem
Run the comamnd to tell the installation where to look for the OS

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## Let the script do the work
Go into the Arch installation and get the files from git but before that few more steps.

```bash
arch-chroot /mnt
git clone https://github.com/samdlaw/quick-arch-deploy.git
cd quick-arch-deploy
chmod +x deploy-arch-uefi.sh
chmod +x install-desktop.sh
./deploy-arch-uefi.sh
```

If you want to install Desktop Environment, run the `install-desktop` script. If system was rebooted, use `sudo` to run the script.
```bash
cd /quick-arch-deploy
./install-desktop.sh
```

[Back to contents](#table-of-contents)