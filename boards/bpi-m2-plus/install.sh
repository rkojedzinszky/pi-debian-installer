# shell fragment

DTB=/usr/lib/linux-image-next-sunxi/sun8i-h3-bananapi-m2-plus.dtb

post_debootstrap()
{
	. boards/common/armbian-kernel.sh
}
