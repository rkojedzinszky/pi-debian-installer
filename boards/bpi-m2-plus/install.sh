# shell fragment

post_debootstrap()
{
	sed -e "s/@UUID@/$rootuuid/g" $rootdir/boot/boot.cmd.template > $rootdir/boot/boot.cmd
	chroot $rootdir mkimage -A arm -T script -C lzma -d /boot/boot.cmd /boot/boot.scr
	chroot $rootdir apt-get install -y --no-install-recommends gnupg2 dirmngr
	chroot $rootdir apt-key adv --keyserver keys.gnupg.net --recv-keys 0x93D6889F9F0E78D5
	echo "deb http://apt.armbian.com jessie main utils" > $rootdir/etc/apt/sources.list.d/armbian.list
	chroot $rootdir apt-get update
	chroot $rootdir apt-get -f -y --no-install-suggests install linux-image-sun8i
}
