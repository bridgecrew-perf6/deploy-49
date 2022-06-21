#!/bin/sh

# Usage: ./install.sh "block device" "tarball" "root passwd"

MOUNT_DIR=/mnt/gentoo

usage() {
    echo "Usage: $0 [block device] [tarball] [root passwd]"
    exit 1
}

if [ $(id -u) -ne 0 ]; then
    exit 1
fi

if [ $# -lt 3 ]; then 
    usage
fi

if [ ! -b $1 ]; then
    echo "block device not found"
fi

if [ ! -f $2 ]; then
    echo "tarball not found"
fi

# partition disk
#   partnum     size    type
#   1           512M    EFI System
#   2           4G      Linux swap
#   3           100%    Linux filesystem
sgdisk -Z $1
sgdisk -o $1
sgdisk -n 1::+512M -t 1:EF00 $1
sgdisk -n 2::+4G   -t 2:8200 $1
sgdisk -n 3::      -t 3:8300 $1
sgdisk -p $1

# create filesystem (assumes nvme)
mkfs.fat -F 32 ${1}p1
mkfs.btrfs ${1}p3
mkswap ${1}p2
swapon ${1}p2

# mount
mkdir -p $MOUNT_DIR
mount ${1}p3 $MOUNT_DIR

# create subvolumes
btrfs subvolume create $MOUNT_DIR/@
btrfs subvolume create $MOUNT_DIR/@home
btrfs subvolume create $MOUNT_DIR/@log
btrfs subvolume create $MOUNT_DIR/@distfiles

umount $MOUNT_DIR 
mount -t btrfs -o defaults,relatime,compress=lzo,autodefrag,subvol=/@ ${1}p3 $MOUNT_DIR

mkdir -p $MOUNT_DIR/{home,boot,var{/log,/cache/distfiles}}
mount -t btrfs -o defaults,ssd,relatime,compress=lzo,autodefrag,subvol=/@home ${1}p3 $MOUNT_DIR/home
mount -t btrfs -o defaults,ssd,relatime,compress=lzo,autodefrag,subvol=/@log  ${1}p3 $MOUNT_DIR/var/log
mount -t btrfs -o defaults,ssd,relatime,autodefrag,subvol=/@distfiles         ${1}p3 $MOUNT_DIR/var/cache/distfiles

mount -t vfat ${1}p1 $MOUNT_DIR/boot

# extract tarball to mount point
tarball=$(realpath $2)
tar xpf $tarball --xattrs-include='*.*' --numeric-owner -C $MOUNT_DIR

# prep chroot
mkdir -p $MOUNT_DIR/etc/portage/repos.conf
cp $MOUNT_DIR/usr/share/portage/config/repos.conf $MOUNT_DIR/etc/portage/repos.conf/gentoo.conf
cp -L /etc/resolv.conf $MOUNT_DIR/etc/

cp $PWD/files/portage/make.conf $MOUNT_DIR/etc/portage/make.conf
cp $PWD/files/etc/hosts         $MOUNT_DIR/etc/hosts

part1_uuid=$(blkid -o value -s UUID ${1}p1)
part2_uuid=$(blkid -o value -s UUID ${1}p2)
part3_uuid=$(blkid -o value -s UUID ${1}p3)

cat << EOF > $MOUNT_DIR/etc/fstab
# <fs>      <mountpoint>    <type>  <opts>                                                      <dump/pass>

# ${1}p1
UUID=$part1_uuid   /boot      vfat     rw,relatime,utf8,errors=remount-ro      0 2

# ${1}p2
UUID=$part2_uuid   none       swap     sw                                      0 0

# ${1}p3
UUID=$part3_uuid   /                     btrfs    defaults,ssd,relatime,compress=lzo,autodefrag,subvol=/@           0 0
UUID=$part3_uuid   /home                 btrfs    defaults,ssd,relatime,compress=lzo,autodefrag,subvol=/@home       0 0
UUID=$part3_uuid   /var/log              btrfs    defaults,ssd,relatime,compress=lzo,autodefrag,subvol=/@log        0 0
UUID=$part3_uuid   /var/cache/distfiles  btrfs    defaults,ssd,relatime,autodefrag,subvol=/@distfiles  		    0 0

EOF

mount -t proc /proc $MOUNT_DIR/proc
mount -R /sys $MOUNT_DIR/sys
mount -R /dev $MOUNT_DIR/dev
mount -B /run $MOUNT_DIR/run

# chroot and execute post-chroot script
cp ./bootstrap.sh $MOUNT_DIR
chroot $MOUNT_DIR ./bootstrap.sh $3

umount -R $MOUNT_DIR
