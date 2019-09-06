#!/usr/bin/bash

# Meant to be run on a fresh installation of ArchLinux.
# This script was written because the last time I installed ArchLinux
# was in 2015 or 2016, and now that I installed it again on the date of
# this commit - 1d, I'm installing packages as they cross my mind.
# Hopefully this script will help my future self someday.
# Some of the packages install other ones as dependencies,
# e.g., gparted installs parted, sshfs installs openssh, et cetera.
# Feel free to fork this repository and adapt this script to fit your needs.

# Check if dialog exists; prompt to install it if it doesn't.
check_dialog() {
    if [[ "$1" != "skipwhich" ]]; then
        which dialog > /dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi

    echo "\`dialog\` is necessary to run this script. Install it now? [y/n]"

    local INSTALL_DIALOG
    read INSTALL_DIALOG

    if [[ "$INSTALL_DIALOG" == "y" ]]; then
        sudo pacman -Sy dialog --noconfirm

    elif [[ "$INSTALL_DIALOG" == "n" ]]; then
        echo "Can't proceed with installation script. Exiting."
        exit 1

    else
        # Answer was neither y nor n. Ask again.
        check_dialog skipwhich
    fi
}

check_dialog

# Show checkbox-list of packages to install, and install them.
# Returns 0 if no packages were installed, 1 if at least 1 package was installed,
# and 2 if git was installed. Git is needed in the next step.
install_packages() {
    local PACKAGES_TO_INSTALL
    PACKAGES_TO_INSTALL=$(dialog \
        --title "ArchLinux fresh install" \
        --no-tags \
        --stdout \
        --checklist "Select packages or <groups>" 0 0 0 \
            xorg "<xorg>" on \
            xorg-drivers "<xorg-drivers>" on \
            xfce4 "<xfce4>" on \
            xfce4-goodies "<xfce4-goodies>" on \
            bash-completion "bash-completion" on \
            curl "curl" on \
            lynx "lynx" off \
            wget "wget" on \
            git "git (required to install packages from AUR)" on \
            dosfstools "dosfstools" on \
            ntfs-3g "ntfs-3g" on \
            gimp "gimp" off \
            libreoffice-fresh "libreoffice-fresh" off \
            network-manager-applet "network-manager-applet" on \
            networkmanager "networkmanager" on \
            wpa_supplicant "wpa_supplicant" on \
            nmap "nmap" on \
            ntp "ntp" on \
            gparted "gparted" on \
            pavucontrol "pavucontrol" on \
            pulseaudio "pulseaudio" on \
            python "python" on \
            redshift "redshift" on \
            rsync "rsync" on \
            rustup "rustup" on \
            sshfs "sshfs" on \
            telegram-desktop "telegram-desktop" off \
            terminator "terminator" on \
            unzip "unzip" off \
            vim "vim" on \
            zip "zip" off
    )
    clear

    if [[ -z "$PACKAGES_TO_INSTALL" ]]; then
        return 0
    fi

    [[ $PACKAGES_TO_INSTALL =~ git ]] && GIT_SELECTED=${BASH_REMATCH[0]}
    sudo pacman -Sy $PACKAGES_TO_INSTALL

    if [[ -n "$GIT_SELECTED" ]]; then
        return 2
    else
        return 1
    fi
}

install_packages
GIT_INSTALLED=$?

# Ask if installing yay-bin from AUR is desired, and install it if it is.
install_yaybin() {
    dialog --title yay --yesno "Install yay-bin from AUR?" 0 0
    local INSTALL_YAY=$?
    clear
    if [[ $INSTALL_YAY -eq 0 ]]; then
        echo "Cloning yay-bin into /tmp"
        pushd /tmp
        git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin
        makepkg -si
        popd
    else
        return 1
    fi
}

[[ $GIT_INSTALLED -eq 2 ]] && install_yaybin
YAY_INSTALLED=$?

# Show some AUR packages to install, in case yay was installed.
install_aur_packages() {
    local AUR_PACKAGES
    AUR_PACKAGES=$(dialog \
        --title "Install packages from AUR" \
        --no-tags \
        --stdout \
        --checklist "Select packages" 0 0 0 \
            fetchmirrors fetchmirrors off \
            google-chrome google-chrome off \
            visual-studio-code-bin visual-studio-code-bin off
    )
    clear

    [[ -n $AUR_PACKAGES ]] && yay -S $AUR_PACKAGES
}

[[ $YAY_INSTALLED -eq 0 ]] && install_aur_packages

echo "Finished."
