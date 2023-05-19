#!/bin/bash

TARGET_ARCH=armhf

: ${TARGET_DIST=bullseye}
: ${DEB_MIRROR=http://deb.debian.org/debian/}
: ${PACKAGES=firmware-brcm80211,e2fsprogs,vim,u-boot-tools,initramfs-tools,xfsprogs,ssh}
: ${BOOT_SIZE=512M}
: ${ROOT_SIZE=2048M}
: ${ROOTFS_TYPE=ext4}
: ${DISKLABEL_TYPE=dos}
: ${DISKLABEL_FIRST_LBA=2048}

DTB=

case "$ROOTFS_TYPE" in
	ext4)
		mkrootfs="mkfs.ext4 -F"
		;;
	xfs)
		mkrootfs="mkfs.xfs -f"
		;;
	*)
		echo "Root filesystem type '$ROOTFS_TYPE' not supported"
		exit 1
		;;
esac

CLEANUP=( )
cleanup() {
  set +e
  if [ ${#CLEANUP[*]} -gt 0 ]; then
    LAST_ELEMENT=$((${#CLEANUP[*]}-1))
    REVERSE_INDEXES=$(seq ${LAST_ELEMENT} -1 0)
    for i in $REVERSE_INDEXES; do
      ${CLEANUP[$i]}
    done
  fi
}
trap cleanup EXIT

get_uuid()
{
	blkid -o value -s UUID $1
}

set -e

if [ $# -ne 2 ]; then
	echo "Usage: $0 <board> <device>"
	echo "Board can be one of:"
	ls -1 boards | grep -v '^common$' | sed -e 's/^/ /'
	exit 1
fi

board="$1"
dev="$2"

. boards/common/install.sh

if [ -f local-install.sh ]; then
	. local-install.sh
fi

hook pre_partitioning

(
echo "label: $DISKLABEL_TYPE"
echo "first-lba: $DISKLABEL_FIRST_LBA"
echo ",${BOOT_SIZE},,*"
echo ",$ROOT_SIZE"
) | flock $dev sfdisk -f -u S $dev

hook post_partitioning

sleep 1

_devices=($(lsblk -n -o name -p -r $dev | sort))

bootdev=${_devices[1]}
rootdev=${_devices[2]}

mkfs.ext3 -F $bootdev
tune2fs -o discard $bootdev
$mkrootfs $rootdev

bootuuid=$(get_uuid $bootdev)
rootuuid=$(get_uuid $rootdev)

rootdir=$(mktemp -d)
CLEANUP+=("rmdir $rootdir")

mount $rootdev $rootdir
CLEANUP+=("umount $rootdir")
mkdir $rootdir/boot
mount -o nobarrier $bootdev $rootdir/boot
CLEANUP+=("umount $rootdir/boot")

export LC_ALL=C LANGUAGE=C LANG=C
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

tar cf - --owner=root:0 --group=root:0 -C boards/common/root . | tar xf - --no-same-permissions -C "$rootdir"
if [ -d "$BOARD_DIR/root" ]; then
	tar cf - --owner=root:0 --group=root:0 -C "$BOARD_DIR/root" . | tar xf - --no-same-permissions -C "$rootdir"
fi

# generate bootEnv.txt
echo "root=UUID=$rootuuid" > "$rootdir/boot/bootEnv.txt"

hook pre_debootstrap

debootstrap --components=main,contrib,non-free --arch $TARGET_ARCH $TARGET_DIST $rootdir $DEB_MIRROR

if [ "$KERNEL" != "" ]; then
	PACKAGES="$PACKAGES,$KERNEL"
fi
case "$TARGET_DIST" in
	bullseye)
		PACKAGES="$PACKAGES,python-is-python3,systemd-timesyncd"
		;;
esac
chroot $rootdir apt-get install -f -y ${PACKAGES//,/ }

hook pre_mkbootscr

# generate boot.scr
chroot $rootdir mkimage -T script -A arm -d /boot/boot.cmd /boot/boot.scr

hook post_debootstrap

hook install_kernel

# prepare dtb
mkdir -p $rootdir/boot/dtb
if [ -n "$DTB" ]; then
	cp $rootdir$DTB $rootdir/boot/dtb/
fi

echo "$board" > $rootdir/etc/hostname

cat <<EOF > $rootdir/etc/fstab
UUID=$bootuuid	/boot		ext3	rw		0	2
UUID=$rootuuid	/		$ROOTFS_TYPE	rw		0	1
EOF

echo "root:pi" | chroot $rootdir chpasswd

chroot $rootdir systemctl enable systemd-timesyncd

U_BOOT="$BOARD_DIR/u-boot-sunxi-with-spl.bin"
if [ -f "$U_BOOT" ]; then
	dd if="$U_BOOT" of=$dev bs=1k seek=8
fi

hook customize
