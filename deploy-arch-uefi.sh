#!/bin/bash
source "./config-files/supported-files/shell-fn.sh"
rm programs-deploy
copyFile "./config-files/supported-files" programs-deploy
#
# Set the correct timezone
# Get list of timezones by running the command `timedatectl list-timezones` and editing the `Region/City` in below line accordingly
# ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
timedatectl set-timezone Europe/London
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
#
# Sync hardware clock
hwclock --systohc
# Update locale. Uncomment for locale
sed -i.bak -e "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
locale-gen
#
rm /etc/locale.conf
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
#
# Update the keymap by running `ls /usr/share/kbd/keymaps/**/*xx*.map.gz` where xx is country code
rm /etc/vconsole.conf
echo "KEYMAP=us" >> /etc/vconsole.conf
#
rm /etc/hostname
echo "sam-arch-pc" >> /etc/hostname
#
rm /etc/hosts
echo "127.0.0.1  localhost" >> /etc/hosts
echo "::1        localhost" >> /etc/hosts
echo "127.0.1.1  sam-arch-pc.localdomain  sam-arch-pc" >> /etc/hosts
#
mkinitcpio -P
#
# Install required packages
listMicrocode=("INTEL" "AMD")
promptOpt "Desktop Environment" "${listMicrocode[@]}"
case "${userOption}" in
    "INTEL")
        echo "intel-ucode" >> programs-deploy
        echo "thermald" >> programs-deploy
        echo "i7z" >> programs-deploy
        ;;
    "AMD")
        echo "amd-ucode" >> programs-deploy
        ;;
esac
#
#
echo "mkinitcpio" >> programs-deploy
listLinuxKernel=("Linux" "Linux LTS" "Both")
promptOpt "Linux Kernel" "${listLinuxKernel[@]}"
if [[ "${userOption}" == "Linux" || "${userOption}" == "Both" ]]; then
    echo "linux" >> programs-deploy
    echo "linux-headers" >> programs-deploy
fi
if [[ "${userOption}" == "Linux LTS" || "${userOption}" == "Both" ]]; then
    echo "linux-lts" >> programs-deploy
    echo "linux-lts-headers" >> programs-deploy
fi
#
pacman -S - < programs-deploy
#
# Enable services
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable cups.service
systemctl enable sshd
systemctl enable reflector.timer
systemctl enable firewalld
systemctl enable fstrim.timer
systemctl enable paccache.timer
systemctl enable acpid
systemctl enable avahi-daemon
systemctl enable libvirtd
#
# Clean up hook for pacman
cp config-files/hooks-pacman/remove_old_cache.hook /etc/pacman.d/hooks/remove_old_cache.hook
chmod -R 644 /etc/pacman.d/hooks/
#
# Reduce Swappiness for SSD
rm /etc/sysctl.d/99-swappiness.conf
echo "#Swappiness" >> /etc/sysctl.d/99-swappiness.conf
echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
sysctl --system
#
# Remove swapfile if it exits and then Add Swap file
# Entry in fstab will be created if there is no swapfile (assumption that swapfile was created properly)
while true; do
    read -p  "Enter the size for swapfile (0 for no swapfile): " swapFlSize
    if [ -z "${swapFlSize}" ]; then
        echo "Swap file size input can not be blank"
    else
        re='^[0-9]+([.][0-9]+)?$'
        if [[ $swapFlSize =~ $re ]] ; then
            break
        else
            echo "Swapfile size is not a number. Try again"
        fi
    fi
done
if [ ${swapFlSize} != 0 ]; then
    while true; do
        echo "Valid suffixes: MB=1000*1000, M=1024*1024, GB=1000*1000*1000, G=1024*1024*1024"
        read -p  "Enter the suffix for swapfile: " swapFlSuffix
        if [ -z "${swapFlSuffix}" ] || [[ ${#swapFlSuffix} > 2 ]]; then
            swapFlSuffix=""
        elif [[ ${#swapFlSuffix} == 1 ]]; then
            sizebs=1024
            swapFlSuffix="${swapFlSuffix:0:1}iB"
        elif [[ "${swapFlSuffix:1:1}" != "B" ]]; then
            swapFlSuffix=""
        elif [[ "${swapFlSuffix:1:1}" == "B" ]]; then
            sizebs=1000
            swapFlSuffix="${swapFlSuffix:0:1}B"
        fi
        #
        case "${swapFlSuffix:0:1}" in
            "M")
                powerCount=2
                break;;
            "G")
                powerCount=3
                break;;
            *)
                echo "Please choose from the provided options"
                ;;
        esac
    done
    #
    if [ -f /swapfile ]; then
        swapoff -v /swapfile
        rm /swapfile
    else
        sed -i.bak -e "/# Swapfile/d" /etc/fstab
        sed -i.bak -e "/\/swapfile       swap            swap    defaults        0       0/d" /etc/fstab
        echo "# Swapfile" >> /etc/fstab
        echo "/swapfile       swap            swap    defaults        0       0" >> /etc/fstab
    fi
    #dd if=/dev/zero of=/swapfile bs=<BYTES> count=<N>
    #N and BYTES may be followed by the following multiplicative suffixes:
    #c=1, w=2, b=512, kB=1000, K=1024, MB=1000*1000, M=1024*1024, xM=M, GB=1000*1000*1000, G=1024*1024*1024, and so on for T, P, E, Z, Y.
    #Binary prefixes can be used, too: KiB=K, MiB=M, and so on.
    echo "Waiting for creation of contigous location for swapfile ${swapFlSize} ${swapFlSuffix}..."
    calcCountStore=`echo "(${sizebs}^(${powerCount}-1))*${swapFlSize}" | bc`
    dd if=/dev/zero of=/swapfile bs=${sizebs} count=${calcCountStore}
    chmod 600 /swapfile
    echo "Waiting for swapfile..."
    mkswap /swapfile
    swapon /swapfile
fi
#
# Update fstab for tmpfs
sed -i.bak -e "/# Use a ramdisk to store temporary data/d" /etc/fstab
sed -i.bak -e "/tmfs \/tmp      tmpfs  defaults,noatime,nosuid,mode=1777  0  0/d" /etc/fstab
sed -i.bak -e "/tmpfs \/run      tmpfs  defaults,noatime,nosuid,mode=1777  0  0/d" /etc/fstab
echo "# Use a ramdisk to store temporary data" >> /etc/fstab
echo "tmpfs /tmp      tmpfs  defaults,noatime,nosuid,mode=1777  0  0" >> /etc/fstab
echo "tmpfs /run      tmpfs  defaults,noatime,nosuid,mode=1777  0  0" >> /etc/fstab
#
# Enable GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
sed -i.bak -e "/GRUB_DISABLE_OS_PROBER=false/d" /etc/fstab
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
#
# Get Full name for new user
while true; do
    read -p  "Enter full name of new user: " newUser
    if [ -z "${newUser}" ]; then
        echo "Username can not be blank. Please try again"
    else
        break
    fi
done
# Get login ID for new user
while true; do
    read -p  "Enter login for new user: " newUserLogin
    if [ -z "${newUserLogin}" ]; then
        echo "Login ID can not be blanks. Try again"
    elif id ${newUserLogin} &>/dev/null ; then
        echo "Login ID ${newUserLogin} already exists. Please try again"
    else
        break
    fi
done
# Get passowrd & confirm it is correct for new user
while true; do
    read -s -p "Enter password for ${newUser}: " newUserPass
    echo ""
    read -s -p "Re-enter password for ${newUser}: " newUserPassConfirm
    echo ""
    if [ -z "${newUserPass}" ] || [ "${newUserPass}" != "${newUserPassConfirm}" ]; then
        echo "Password is blank or do not match. Try again"
    else
        break
    fi
done
#
while true; do
    read -p  "Do you want same password for root? (y/N): " responseYN
    case ${responseYN} in 
        [Yy]*) 
            newRootPass="${newUserPass}"
            break;;
        [Nn]*)
            read -p  "Enter new password for root: " newRootPass
            break;;
        *) echo "Please enter only Y or N"
            ;;
    esac
done
#
# Change root user password
echo root:${newRootPass} | chpasswd
sed -i.bak -e "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers
#
# Add new user
useradd -m -G wheel -s /bin/bash -c "${newUser}" -U ${newUserLogin}
echo ${newUserLogin}:${newUserPass} | chpasswd
usermod -aG libvirt ${newUser}
#
# Add specific settings
cp -a config-files/dot-files-home/. /home/${newUser}/
#
rm programs-deploy
# Final message
echo -e "\e[1;32mAll done. You may continue configuring the system. Once done, key in following\e[0m"
echo -e "\e[1;32m1. \"exit\" to quit arch-chroot\n2. \"umount -a\" to remove all mounted files\n3. \"reboot\" to start\e[0m"