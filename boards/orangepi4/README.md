# Orange PI 4 boot files

idbloader.img:
```
$ mkimage -n rk3399 -T rksd -d bin/rk33/rk3399_ddr_933MHz_v1.24.bin idbloader.img
$ cat bin/rk33/rk3399_miniloader_v1.24.bin >> idbloader.img
```

trust.img:
```
$ cp RKTRUST/RK3399TRUST.ini trust.ini
$ # Remove BL32_OPTION in .ini
$ ./tools/trust_merger ./trust.ini
```

uboot.img
```
$ cd ../u-boot
$ # u-boot config:
$ make evb-rk3399_defconfig
$ sed -i -e '/^CONFIG_DEFAULT_FDT_FILE/s,=.*,="rockchip/rk3399-orangepi-4.dtb",' .config
$ make -j4 u-boot-dtb.bin
$ ../rkbin/tools/loaderimage --pack --uboot u-boot-dtb.bin uboot.img 0x00200000
```
