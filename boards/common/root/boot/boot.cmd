setenv load_addr "0x45000000"
setenv envFile bootEnv.txt

if test -e ${devtype} ${devnum} ${prefix}${envFile}; then
	load ${devtype} ${devnum} ${load_addr} ${prefix}${envFile}
	env import -t ${load_addr} ${filesize}
fi

setenv bootargs console=ttyS0,115200 console=tty1 root=${root} rw rootwait panic=10 ${extra}
load ${devtype} ${devnum}:${bootpart} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
load ${devtype} ${devnum}:${bootpart} ${kernel_addr_r} ${prefix}${kernel}
load ${devtype} ${devnum}:${bootpart} ${ramdisk_addr_r} ${prefix}${uinitrd}
bootz ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
