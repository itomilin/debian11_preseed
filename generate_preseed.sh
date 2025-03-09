#!/usr/bin/env bash

set -e

envsubst -V
if [[ $? -ne 0 ]]; then
  echo "Error: install envsubst utility"
  exit 1
fi

mode=$1
if [[ $mode == "nointeractive" ]]
then
  hostname=$2
  root_password=$3
  username=$4
  user_password=$5
  network=$6
  host=$7
else
  echo "Input hostname (also used for the preseed file name):"
  read hostname

  echo "Input root password (shadow):"
  read -s root_password

  echo "Input username:"
  read username

  echo "Input user password (shadow):"
  read -s user_password

  echo "Input network:"
  read network

  echo "Input host:"
  read host
fi


if [[ -z $root_password || -z $user_password || -z $username || -z $hostname || -z $network || -z $host ]]; then
    echo "Error: check input."
    exit 1
fi

# vda libvirt by default
GRUB_TARGET="/dev/vda"
export __COUNTRY="RU"
export __LOCALES=",ru_RU.UTF-8"
export __TIMEZONE="Europe/Moscow"
export __EFI_PARTITION_SIZE_MB=512
export __ROOT_PARTITION_SIZE_MB=51200
export __HOSTNAME=$hostname
export __PACKAGES_MIRROR="deb.debian.org"
export __USERNAME=$username
export __ROOT_PASSWORD=`echo $root_password | openssl passwd -6 -noverify -stdin`
export __USER_PASSWORD=`echo $user_password | openssl passwd -6 -noverify -stdin`
# export __BASE_UTILITIES="standard,ssh-server"
export __BASE_UTILITIES="ssh-server"
export __POST_INSTALL_SCRIPT="post_cmd_kvm.sh"
export __NETWORK=$network
export __HOST=$host

export __EFI_PARTITION="
    ${__EFI_PARTITION_SIZE_MB}  30  ${__EFI_PARTITION_SIZE_MB} fat32 \
        \$primary{ }                   \
        \$reusemethod{ }               \
        \$iflabel{ gpt }               \
        method{ efi }                 \
        format{ }                     \
    . \
"
export __EFI_PARTITION="" # comment if needed

# All free space to the end of the disk.
export __HOME_PARTITION="\\
    100   100 -1       ext4           \\
        \$primary{ }                   \\
        label{ home }                 \\
        method{ format }              \\
        format{ }                     \\
        use_filesystem{ }             \\
        filesystem{ ext4 }            \\
        options/noatime{ noatime }    \\
        options/discard{ discard }    \\
        mountpoint{ /home }           \\
    ."
export __HOME_PARTITION="" # comment if needed

# disable grub (It is assumed to use another bootloader from the post_cmd script, such as systemd-networkd.)
export __GRUB_BOOTLOADER="
d-i grub-installer grub-installer/grub_not_mature_on_this_platform boolean false
d-i grub-installer grub-installer/grub2_instead_of_grub_legacy     boolean false
d-i grub-installer grub-installer/sataraid                         boolean false
d-i grub-installer grub-installer/force-efi-extra-removable        boolean false
d-i grub-installer grub-installer/skip                             boolean true 
d-i grub-installer grub-installer/with_other_os                    boolean false
d-i grub-installer grub-installer/make_active                      boolean false
d-i grub-installer grub-installer/only_debian                      boolean false
d-i grub-installer grub-installer/bootdev                          string  /dev/null
d-i grub-installer grub-installer/multipath                        boolean false
"
# enable grub (This method is suitable for a VM without UEFI)
export __GRUB_BOOTLOADER="
d-i grub-installer/only_debian   boolean false
d-i grub-installer/with_other_os boolean false
# To install to the primary device (assuming it is not a USB stick):
d-i grub-installer/bootdev       string  default
"

envsubst \
  '${__COUNTRY} \
   ${__LOCALES} \
   ${__USERNAME} \
   ${__TIMEZONE} \
   ${__EFI_PARTITION_SIZE_MB} \
   ${__ROOT_PARTITION_SIZE_MB} \
   ${__HOSTNAME} \
   ${__PACKAGES_MIRROR} \
   ${__ROOT_PASSWORD} \
   ${__USER_PASSWORD} \
   ${__BASE_UTILITIES} \
   ${__EFI_PARTITION} \
   ${__HOME_PARTITION} \
   ${__GRUB_BOOTLOADER} \
   ${__POST_INSTALL_SCRIPT} \
   ${__NETWORK} \
   ${__HOST} \
   ' < ./preseed_tpl > preseeds/$hostname

echo "File generated to ./preseeds/$hostname"