#!/bin/bash

TARGET_ARCH=armhf
TARGET_DIST=stretch
DEB_MIRROR=http://dev.euronetrt.hu:3142/debian/
PACKAGES=firmware-brcm80211,e2fsprogs,vim,u-boot-tools,cpufrequtils
USE_LVM=yes
ROOT_SIZE=2048M
SWAP_SIZE=1024M

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

hook pre_partitioning

if [ "$USE_LVM" = yes ]; then
	cat <<-EOF
	,256M,83,*
	,,8e,*
	EOF
else
	cat <<-EOF
	,256M,83,*
	,$SWAP_SIZE,82
	,$ROOT_SIZE
	EOF
fi | sfdisk -f -u S $dev
sleep 1

hook post_partitioning

_devices=($(lsblk -n -o name -p -r $dev))

bootdev=${_devices[1]}
if [ "$USE_LVM" = yes ]; then
	physdev=${_devices[2]}
	vgname="$board-$RANDOM"
	vgcreate "$vgname" "$physdev"
	CLEANUP+=("vgchange -a n $vgname")

	lvcreate -W y -n swap -L $SWAP_SIZE $vgname
	swapdev="/dev/$vgname/swap"
	lvcreate -W y -n root -L $ROOT_SIZE $vgname
	rootdev="/dev/$vgname/root"
	PACKAGES="$PACKAGES,lvm2"
else
	swapdev=${_devices[2]}
	rootdev=${_devices[3]}
fi

mkfs.ext3 -F $bootdev
tune2fs -o journal_data_writeback,discard $bootdev
mkswap -f $swapdev
mkfs.ext4 -F $rootdev
tune2fs -o journal_data_writeback,discard $rootdev

bootuuid=$(get_uuid $bootdev)
swapuuid=$(get_uuid $swapdev)
rootuuid=$(get_uuid $rootdev)

rootdir=$(mktemp -d)
CLEANUP+=("rmdir $rootdir")

mount -o nobarrier $rootdev $rootdir
CLEANUP+=("umount $rootdir")
mkdir $rootdir/boot
mount -o nobarrier $bootdev $rootdir/boot
CLEANUP+=("umount $rootdir/boot")

export LC_ALL=C LANGUAGE=C LANG=C
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

tar cf - -C boards/common/root . | tar xf - -C "$rootdir"
if [ -d "$BOARD_DIR/root" ]; then
	tar cf - -C "$BOARD_DIR/root" . | tar xf - -C "$rootdir"
fi

# fix/hardcode root= kernel parameter
sed -i -e "s,@ROOT@,UUID=$rootuuid,g" "$rootdir/boot/boot.cmd.template"

if [ $(dpkg --print-architecture) != $TARGET_ARCH ]; then
	mkdir -p $rootdir/usr/bin/
	cp /usr/bin/qemu-arm-static $rootdir/usr/bin/ # XXX
	CLEANUP+=("rm $rootdir/usr/bin/qemu-arm-static")
fi

hook pre_debootstrap

debootstrap --components=main,contrib,non-free --arch $TARGET_ARCH $TARGET_DIST $rootdir $DEB_MIRROR

chroot $rootdir apt-get install -f -y ${PACKAGES//,/ }

hook post_debootstrap

echo "$board" > $rootdir/etc/hostname

cat <<EOF > $rootdir/etc/fstab
UUID=$bootuuid	/boot		ext3	rw,discard	0	2
UUID=$swapuuid	none		swap	sw		0	0
UUID=$rootuuid	/		ext4	rw,discard	0	1
EOF

echo 'GOVERNOR="conservative"' > $rootdir/etc/default/cpufrequtils

echo "root:pi" | chroot $rootdir chpasswd

chroot $rootdir systemctl enable systemd-timesyncd

U_BOOT="$BOARD_DIR/u-boot-sunxi-with-spl.bin"
if [ -f "$U_BOOT" ]; then
	dd if="$U_BOOT" of=$dev bs=1k seek=8
fi
