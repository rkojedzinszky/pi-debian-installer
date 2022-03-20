# Orange PI 4 boot files

Follow generic boot file generation with one modification:
After u-boot make defconfig:

```sh
$ sed -i -e '/^CONFIG_DEFAULT_FDT_FILE/s,=.*,="rockchip/rk3399-orangepi-4.dtb",' .config
```

And go ahead with the rest.
