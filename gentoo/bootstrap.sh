#!/bin/sh

#usage ./bootstrap.sh "root passwd"

source /etc/profile

# packages
emerge-webrsync
eselect profile set default/linux/amd64/17.1/hardened
emerge -vquDN @world
emerge -vqc

# timezone
echo "America/New_York" > /etc/timezone
emerge --config sys-libs/timezone-data

# locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
eselect locale set en_US.utf8

env-update && source /etc/profile

# kernel
emerge -vq sys-kernel/linux-firmware sys-kernel/gentoo-sources sys-kernel/genkernel
eselect kernel set 1
genkernel all

# networking
netif=$(basename /sys/class/net/enp*)
emerge -vnq net-misc/dhcpcd net-misc/netifrc
echo "hostname=\"aisaka-gentoo\"" > /etc/conf.d/hostname
echo "config_${netif}=\"dhcp\"" > /etc/conf.d/net

ln -s /etc/init.d/net.lo /etc/init.d/net.$netif
rc-update add net.$netif default

# change root password
eval "echo root:$1 | chpasswd"

# system maintenance
emerge -vq app-admin/metalog sys-process/cronie sys-apps/mlocate app-editors/neovim

# filesystem tools
emerge -vq sys-fs/e2fsprogs sys-fs/btrfs-progs

# portage tools
emerge -vq app-portage/gentoolkit

# bootloader
emerge -vq sys-boot/grub sys-boot/os-prober
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
