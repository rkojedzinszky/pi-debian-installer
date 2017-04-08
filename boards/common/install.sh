# common functions

hook()
{
	local hook_name="$1"

	echo "Calling $hook_name"
	$hook_name
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
