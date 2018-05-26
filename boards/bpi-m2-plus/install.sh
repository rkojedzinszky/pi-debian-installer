# shell fragment

post_debootstrap()
{
	chroot $rootdir apt-get install -y --no-install-recommends gnupg2 dirmngr
	chroot $rootdir apt-key adv --keyserver keys.gnupg.net --recv-keys 0x93D6889F9F0E78D5
	echo "deb http://apt.armbian.com jessie main utils" > $rootdir/etc/apt/sources.list.d/armbian.list
	chroot $rootdir apt-get update
	chroot $rootdir apt-get -f -y --no-install-suggests install linux-image-next-sunxi initramfs-tools
}
