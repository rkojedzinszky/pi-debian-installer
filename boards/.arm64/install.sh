# replace bootz with booti
pre_mkbootscr()
{
	sed -i -e "s/console=ttyS0,115200/console=ttyS0,1500000/" -e "s/^bootz/booti/" "$rootdir/boot/boot.cmd"
}
