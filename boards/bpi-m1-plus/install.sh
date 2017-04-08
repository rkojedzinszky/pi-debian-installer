post_debootstrap()
{
	chroot $rootdir apt-get install -f -y linux-image-armmp
}
