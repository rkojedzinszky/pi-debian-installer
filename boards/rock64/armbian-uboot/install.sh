#!/bin/sh

set -e

dev="$1"
test -b "$dev"

dd of=$dev if=idbloader.bin seek=64
dd of=$dev if=uboot.img seek=16384
dd of=$dev if=trust.bin seek=24576
