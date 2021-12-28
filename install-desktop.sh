#!/bin/bash
source "./config-files/supported-files/shell-fn.sh"
rm programs-desktop
copyFile "./config-files/supported-files" programs-desktop
# Install nvidia drivers. If LTS kernel is used, then use nvidia-lts
prompt "Do you want to install proprietary NVIDIA drivers?"
if [[ "${userResponse}" == "Y" ]]; then
    driversNVIDIA="Y"
    prompt "Are you using LTS kernel?"
    if [[ "${userResponse}" == "Y" ]]; then
        echo "nvidia" >> programs-desktop
    else
        echo "nvidia-lts" >> programs-desktop
    fi
    echo "nvidia-utils" >> programs-desktop
else
    unset driversNVIDIA
fi
#
# Install based on option provided
listDE=("GNOME" "KDE" "XFCE")
systemctl disable gdm sddm lightdm
promptOpt "Desktop Environment" "${listDE[@]}"
case "${userOption}" in
# Install GNOME Desktop Environment
    "GNOME")
        echo "Installing gnomde desktop..."
        cat >> programs-desktop << EOL
gdm
gnome
gnome-software-packagekit-plugin
gnome-tweaks
gnome-shell-extensions
baobab
sushi
guake
EOL
        prompt "Do you want to install additional GNOME software?"
        if [[ "${userResponse}" == "Y" ]]; then
            echo "gnome-extra" >> programs-desktop
        fi
        systemctl enable gdm
        ;;
# Install KDE Desktop Environment
    "KDE")
        echo "Installing kde plasma desktop..."
        cat >> programs-desktop << EOL
sddm
plasma
plasma-nm
plasma-wayland-session
powerdevil
yakuake
EOL
        if ! [ -z ${driversNVIDIA+x} ]; then 
            echo "egl-wayland" >> programs-desktop
        fi
        prompt "Do you want to install additional KDE software?"
        if [[ "${userResponse}" == "Y" ]]; then
            echo "kde-applications" >> programs-desktop
        fi
        systemctl enable sddm
        ;;
# Install XFCE Desktop Environment
    "XFCE")
        echo "Installing xfce desktop..."
        cat >> programs-desktop << EOL
lightdm
lightdm-gtk-greeter
xfce4
xfce4-goodies
EOL
        systemctl enable lightdm
        ;;
esac
#
# Install Apps
pacman -S - < programs-desktop
#
rm programs-desktop
# Final message
echo -e "\e[1;32mAll done. You may continue configuring the system. \"reboot\" to apply changes\e[0m"