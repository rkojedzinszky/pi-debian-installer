
# install armbian kernel
chroot $rootdir apt-get install -y --no-install-recommends gnupg2 dirmngr apt-transport-https ca-certificates
chroot $rootdir apt-key adv --keyserver keys.gnupg.net --recv-keys 0x93D6889F9F0E78D5
echo "deb https://apt.armbian.com stretch main utils" > $rootdir/etc/apt/sources.list.d/armbian.list
chroot $rootdir apt-get update
chroot $rootdir apt-get -f -y install linux-image-next-sunxi
