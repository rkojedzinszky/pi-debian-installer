setenv load_addr "0x45000000"
setenv envFile bootEnv.txt

if test -e ${devtype} ${devnum} ${prefix}${envFile}; then
	load ${devtype} ${devnum} ${load_addr} ${prefix}${envFile}
	env import -t ${load_addr} ${filesize}
fi

if test "${safe_kernel}" != ""; then
	setenv bootmenu_0 Normal Boot=
	setenv bootmenu_1 Safe Boot=setenv safe_boot 1
	bootmenu 10
fi

if test "${safe_boot}" -eq 1; then
	if test "${safe_kernel}" != ""; then
		setenv kernel ${safe_kernel}
	fi
	if test "${safe_uinitrd}" != ""; then
		setenv uinitrd ${safe_uinitrd}
	fi
	if test "${safe_fdtfile}" != ""; then
		setenv fdtfile ${safe_fdtfile}
	fi
	setenv overlays
fi

load ${devtype} ${devnum}:${bootpart} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
fdt addr ${fdt_addr_r}
fdt resize 65536

echo "Loading ${kernel} and ${uinitrd}"
setenv bootargs console=ttyS2,1500000 console=tty1 root=${root} rw rootwait panic=10 ${extra}
load ${devtype} ${devnum}:${bootpart} ${kernel_addr_r} ${prefix}${kernel}
load ${devtype} ${devnum}:${bootpart} ${ramdisk_addr_r} ${prefix}${uinitrd}

if test "${safe_boot}" -eq 1; then
	booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
fi

# from armbian
for overlay_file in ${overlays}; do
	if load ${devtype} ${devnum} ${load_addr} ${prefix}dtb/overlay/${overlay_prefix}-${overlay_file}.dtbo; then
		echo "Applying kernel provided DT overlay ${overlay_prefix}-${overlay_file}.dtbo"
		fdt apply ${load_addr}
	fi
done
if load ${devtype} ${devnum} ${load_addr} ${prefix}dtb/overlay/${overlay_prefix}-fixup.scr; then
	echo "Applying kernel provided DT fixup script (${overlay_prefix}-fixup.scr)"
	source ${load_addr}
fi

booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
