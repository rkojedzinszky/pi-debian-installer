# replace bootz with booti
pre_mkbootscr()
{
	sed -i -e "s/^bootz/booti/" "$rootdir/boot/boot.cmd"
}
