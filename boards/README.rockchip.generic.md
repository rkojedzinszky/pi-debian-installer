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
$ BL31=../rkbin/bin/rk*/rk*bl31*elf ROCKCHIP_TPL=../rkbin/bin/rk*/rk*_ddr_.bin make -j4
```

Install them like:

```sh
dd if=idbloader.img of=$dev seek=64
dd if=u-boot.itb of=$dev seek=16384
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

Install them like:

```sh
dd if=idbloader.img of=$dev seek=64
dd if=uboot.img of=$dev seek=16384
dd if=trust.img of=$dev seek=24576
```
