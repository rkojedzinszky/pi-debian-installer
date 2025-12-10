#!/bin/sh

set -e

if ! test -f "$BL31"; then
	echo "[-] \$BL31 does not point to a file"
fi
if ! test -f "$ROCKCHIP_TPL"; then
	echo "[-] \$ROCKCHIP_TPL does not point to a file"
fi

make rock64-rk3328_defconfig
scripts/config --enable ROCKCHIP_EXTERNAL_TPL
make olddefconfig
make -j8
