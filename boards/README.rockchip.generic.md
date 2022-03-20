# Generic rockchip bootloader with rkbin

Clone u-boot and rkbin:

```sh
$ git clone git://git.denx.de/u-boot.git
$ git clone https://github.com/rockchip-linux/rkbin.git
```

## Without miniloader

Generate `idbloader.img` and `u-boot.itb`:

```sh
$ cd u-boot
$ make <defconfig>
$ export BL31=../rkbin/bin/rkxx/*.elf
$ make u-boot.itb spl/u-boot-spl.bin
$ ./tools/mkimage -T rksd -n <soc> -d ../rkbin/bin/rkxx/*ddr*.bin:spl/u-boot-spl.bin idbloader.img
```

## With rockchip miniloader

Generate `idbloader.img`:

```sh
$ cd rkbin
$ ./tools/mkimage -T rksd -n <soc> -d bin/rkxx/*ddr*.bin:bin/rkxx/*miniloader.bin idbloader.img
```

Generate `trust.img`:

```sh
$ cp RKTRUST/RK<soc>TRUST.ini trust.ini
$ # disable BL32_OPTION in trust.ini
$ ./tools/trust_merger ./trust.ini
```

Generate `uboot.img`:

```sh
$ cd ../u-boot
$ make <defconfig>
$ make u-boot-dtb.bin
$ ../rkbin/tools/loaderimage --pack --uboot u-boot-dtb.bin uboot.img 0x00200000
```
