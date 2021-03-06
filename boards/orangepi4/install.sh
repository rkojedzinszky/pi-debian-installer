# shell fragment

TARGET_ARCH=arm64

DISKLABEL_TYPE=gpt
DISKLABEL_FIRST_LBA=32768

post_partitioning()
{
	dd if=idbloader.img of=$dev seek=64
	dd if=uboot.img of=$dev seek=16384
	dd if=trust.img of=$dev seek=24576
}
