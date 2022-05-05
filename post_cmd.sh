#!/bin/bash

if [[ -z $1 ]]
then
    exit 1
fi

# Change for another system.
HOSTNAME="${1}"

################################################################################

readonly USER=`id -nu 1000`
readonly IFACE=`ip a | pcregrep -o1 '^2: ([a-z0-9]+)'`
readonly ROOT_PARTITION=`blkid -L root`
readonly KERNEL_RELEASE=`uname -r`
readonly KERNEL="vmlinuz-${KERNEL_RELEASE}"
readonly INITRD="initrd.img-${KERNEL_RELEASE}"
readonly DISTR_RELEASE=`lsb_release -r | awk '{ print $2 }'`
readonly DISTR_ID=`lsb_release -i | awk '{ print tolower( $3 ) }'`

systemd_boot_install () {
    # Cleanup old efi partition.
    rm -Rf /boot/efi/*

    # Systemd-boot.
    bootctl install

    printf '%s\n%s\n%s\n'   \
           'default debian' \
           'timeout 1'      \
           'editor  1' > /boot/efi/loader/loader.conf

    printf '%s\n%s\n%s\n%s\n'   \
           'title   debian'     \
           "linux   /${KERNEL}" \
           "initrd  /${INITRD}" \
           "options root=${ROOT_PARTITION} rw quiet" \
           > /boot/efi/loader/entries/debian.conf

    cp /boot/${KERNEL} /boot/efi/
    cp /boot/${INITRD} /boot/efi/
}

systemd_networkd_install () {
    # Disable networking.
    systemctl stop networking.service
    systemctl mask networking.service
    rm /etc/network/interfaces

    # Setup system-networkd.
    printf '%s\n%s\n%s\n%s\n' \
           "[Match]"                  \
           "Name=${IFACE}"            \
           "[Network]"                \
           "DHCP=true"                \           
           > /etc/systemd/network/01_lan.network

    # Enable daemon.
    systemctl enable systemd-networkd.service
}

final_install () {
    # Set editor by default.
    update-alternatives --set editor /usr/bin/vim.basic
    # Sudo privileges.
    echo "%${USER} ALL=(ALL:ALL) ALL" > /etc/sudoers.d/niias
    # Fix hostname.
    echo "${HOSTNAME}" > /etc/hostname
    sed -i "2s/debian/${HOSTNAME}/g" /etc/hosts
    # TMP FIX.
    #sed -i "2s/.*/127.0.1.1     ${HOSTNAME}/g" /etc/hosts
    # Remove deb-src repos.
    sed -i "/^deb-src/s/^/#/" /etc/apt/sources.list
}

systemd_boot_install
systemd_networkd_install
final_install

