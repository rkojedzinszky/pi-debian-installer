# shell fragment

DTB=/usr/lib/linux-image-next-sunxi/sun8i-h3-orangepi-plus2e.dtb

post_debootstrap()
{
	. boards/common/armbian-kernel.sh
}
