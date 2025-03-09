#!/usr/bin/env bash

NETWORK=$1
HOST=$2

if [[ -z $NETWORK || -z $HOST ]]; then
    echo "Error: check input."
    exit 1
fi

systemd_networkd_install() {
    local IFACE=`ip a | perl -ne 'print "$1" if /^2: ([a-z0-9]+):/'`
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
    rm -fv /etc/network/interfaces

    # Enable daemon.
    systemctl enable --now systemd-networkd.service 
}

grub_set_timeout() {
    sed -i -e 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    update-grub || true
    update-grub2 || true
}

grub_set_timeout
systemd_networkd_install

echo "DONE"

exit 0
