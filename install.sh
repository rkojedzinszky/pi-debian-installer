#!/bin/bash

TARGET_ARCH=armhf

: ${TARGET_DIST=trixie}
: ${DEB_MIRROR=http://deb.debian.org/debian/}
: ${PACKAGES=systemd-sysv,ssh,libpam-systemd,dbus,e2fsprogs,xfsprogs,dosfstools,grub-efi,initramfs-tools,vim,systemd-timesyncd,zstd}
: ${ESP_SIZE=100M}
: ${ROOT_SIZE=16G}
: ${ROOTFS_TYPE=xfs}
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
echo ",${ESP_SIZE},U,*"
echo ",$ROOT_SIZE"
) | sfdisk --lock -f -u S $dev

hook post_partitioning

sleep 1

_devices=($(lsblk -n -o name -p -r $dev | sort))

espdev=${_devices[1]}
rootdev=${_devices[2]}

mkdosfs -F 32 $espdev
$mkrootfs $rootdev

espuuid=$(get_uuid $espdev)
rootuuid=$(get_uuid $rootdev)

rootdir=$(mktemp -d)
CLEANUP+=("rmdir $rootdir")

mount $rootdev $rootdir
CLEANUP+=("umount $rootdir")
mkdir -p $rootdir/boot/efi
mount $espdev $rootdir/boot/efi
CLEANUP+=("umount $rootdir/boot/efi")

export LC_ALL=C LANGUAGE=C LANG=C
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

hook pre_debootstrap

if [[ "$TARGET_DIST" =~ bullseye|bookworm ]]; then
	PACKAGES="$PACKAGES,python-is-python3"
fi

debootstrap --variant=minbase --include=${PACKAGES} --components=main,contrib --arch $TARGET_ARCH $TARGET_DIST $rootdir $DEB_MIRROR

tar cf - --owner=root:0 --group=root:0 -C boards/common/root . | tar xhf - --no-same-permissions -C "$rootdir"
if [ -d "$BOARD_DIR/root" ]; then
	tar cf - --owner=root:0 --group=root:0 -C "$BOARD_DIR/root" . | tar xhf - --no-same-permissions -C "$rootdir"
fi

hook post_debootstrap

hook install_kernel

# tune and setup grub
sed -i -e "/^GRUB_CMDLINE_LINUX=/s/=.*/=\"net.ifnames=0\"/" "$rootdir/etc/default/grub"
mount --bind /dev $rootdir/dev
CLEANUP+=("umount $rootdir/dev")
mount --bind /proc $rootdir/proc
CLEANUP+=("umount $rootdir/proc")
mount --bind /sys $rootdir/sys
CLEANUP+=("umount $rootdir/sys")
chroot $rootdir grub-install --removable
chroot $rootdir update-grub

echo "$board" > $rootdir/etc/hostname

cat <<EOF > $rootdir/etc/fstab
UUID=$espuuid /boot/efi vfat rw 0 2
UUID=$rootuuid / $ROOTFS_TYPE rw 0 1
EOF

echo "root:pi" | chroot $rootdir chpasswd

chroot $rootdir systemctl enable systemd-timesyncd systemd-networkd

U_BOOT="$BOARD_DIR/u-boot-sunxi-with-spl.bin"
if [ -f "$U_BOOT" ]; then
	dd if="$U_BOOT" of=$dev bs=1k seek=8
fi

hook customize

# tune initramfs MODULES
sed -i -e "/^MODULES=/s/=.*/=dep/" "$rootdir/etc/initramfs-tools/initramfs.conf"
