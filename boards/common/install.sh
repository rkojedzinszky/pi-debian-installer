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

pre_mkbootscr()
{
	:
}

post_debootstrap()
{
	:
}

install_kernel()
{
	case ${TARGET_ARCH} in
		armhf)
			chroot $rootdir apt-get install -y linux-image-armmp
			;;
		arm64)
			chroot $rootdir apt-get install -y linux-image-arm64
			;;
	esac
}

customize()
{
	:
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

if [ -n "$TARGET_ARCH" ]; then
	if [ -f "boards/.${TARGET_ARCH}/install.sh" ]; then
		. boards/.${TARGET_ARCH}/install.sh
	fi
fi
