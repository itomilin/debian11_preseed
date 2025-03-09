#!/usr/bin/env bash

NETWORK=$1
HOST=$2

if [[ -z $NETWORK || -z $HOST ]]; then
    echo "Error: check input."
    exit 1
fi

################################################################################

readonly USER=`id -nu 1000`
readonly IFACE=`ip a | perl -ne 'print "$1" if /^2: ([a-z0-9]+):/'`
readonly ROOT_PARTITION=`blkid -L root`
readonly KERNEL_RELEASE=`uname -r`
readonly KERNEL="vmlinuz-${KERNEL_RELEASE}"
readonly INITRD="initrd.img-${KERNEL_RELEASE}"
readonly DISTR_RELEASE=`lsb_release -r | awk '{ print $2 }'`
readonly DISTR_ID=`lsb_release -i | awk '{ print tolower( $3 ) }'`

systemd_boot_install() {
    # Cleanup old efi partition.
    rm -Rf /boot/efi/*

    # Systemd-boot.
    bootctl install

    printf '%s\n%s\n%s\n'   \
           'default debian' \
           'timeout 1'      \
           'editor  1'      \
           > /boot/efi/loader/loader.conf

    printf '%s\n%s\n%s\n%s\n'   \
           'title   debian'     \
           "linux   /${KERNEL}" \
           "initrd  /${INITRD}" \
           "options root=${ROOT_PARTITION} rw quiet" \
           > /boot/efi/loader/entries/debian.conf

    cp /boot/$KERNEL /boot/efi/
    cp /boot/$INITRD /boot/efi/
}

systemd_networkd_install() {
    # Setup system-networkd.
    cat \
<< EOF > /etc/systemd/network/01_lan.network
[Match]
Name=${IFACE}

[Network]
DHCP=false
Address=${NETWORK}.${HOST}/24
Gateway=${NETWORK}.1
DNS=${NETWORK}.1
DNS=8.8.8.8

EOF

    # Disable networking.
    systemctl disable --now networking.service
    systemctl mask networking.service
    rm /etc/network/interfaces

    # Enable daemon.
    systemctl enable --now systemd-networkd.service
}

final_setup() {
    # Set editor by default.
    update-alternatives --set editor /usr/bin/vim.basic

    # Sudo privileges.
    echo "%${USER} ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$USER

    # Comment deb-src repos.
    sed -i "/^deb-src/s/^/#/" /etc/apt/sources.list
}

systemd_boot_install
systemd_networkd_install
final_setup
