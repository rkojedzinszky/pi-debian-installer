# common functions

hook()
{
	local hook_name="$1"

	echo "Calling $hook_name"
	(cd $BOARD_DIR && $hook_name)
}

# defined hooks
pre_partitioning()
{
	:
}

post_partitioning()
{
	:
}

pre_debootstrap()
{
	:
}

post_debootstrap()
{
	:
}

install_kernel()
{
	# install krichy server kernel
	chroot $rootdir apt-get install -y --no-install-recommends gnupg2 dirmngr
	chroot $rootdir apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0x2ADADF37C3C302A7BADABCC10D946CE6DD9F32EB
	echo "deb http://apt.srv.kojedz.in/ ${TARGET_DIST} main" > $rootdir/etc/apt/sources.list.d/apt.srv.kojedz.in.list
	chroot $rootdir apt-get update
	chroot $rootdir apt-get -f -y install linux-image-ks
}

if [ "$board" = "common" ]; then
	echo "Board type '$board' is reserved"
	exit 1
fi

BOARD_DIR="boards/$board"
if ! test -d "$BOARD_DIR"; then
	echo "E: Specified board '$board' does not supported"
	exit 1
fi

if [ -f $BOARD_DIR/install.sh ]; then
	. $BOARD_DIR/install.sh
fi
