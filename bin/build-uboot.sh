#!/bin/sh

: ${UBOOT_SRC=../u-boot}
: ${RKBIN_SRC=../rkbin}
: ${RKBIN_BIN=${RKBIN_SRC}/bin}

usage()
{
	echo "Usage: $0 board [board...]"
	exit 1
}

log()
{
	echo "[$(LANG=C date)] $@"
}

if [ $# -eq 0 ]; then
	usage
fi

BOARDS="$(dirname "$0")/../boards"

clean_env()
{
	# These variables may be set during a build
	BOARD_DIR=
	UBOOT_CONFIG=
	UBOOT_CONFIG_DEFAULT_FDT_FILE=
	BL31=
	ROCKCHIP_TPL=
}

source_env()
{
	local board="$1"

	BOARD_DIR="${BOARDS}/${board}"
	UBOOT_CONFIG_FILE="${BOARD_DIR}/uboot.conf"

	if ! [ -f "${UBOOT_CONFIG_FILE}" ]; then
		echo "[-] ${board} is not supported"
		exit 2
	fi

	log "Loading configuration for board ${board}"

	. "${UBOOT_CONFIG_FILE}"
}

clean_uboot()
{
	log "Cleaning u-boot"
	(
		cd "${UBOOT_SRC}"
		git clean -d -x -f
	)
}

configure_uboot()
{
	log "Configuring u-boot for ${board} using ${UBOOT_CONFIG}"

	make -C "${UBOOT_SRC}" "${UBOOT_CONFIG}"
	if [ -n "${UBOOT_CONFIG_DEFAULT_FDT_FILE}" ]; then
		(cd "${UBOOT_SRC}" && scripts/config --set-str "DEFAULT_FDT_FILE" "${UBOOT_CONFIG_DEFAULT_FDT_FILE}")
	fi
	if [ -n "${ROCKCHIP_TPL}" ]; then
		(cd "${UBOOT_SRC}" && scripts/config --enable "ROCKCHIP_EXTERNAL_TPL")
	fi
	make -C "${UBOOT_SRC}" olddefconfig
}

build_uboot()
{
	log "Building u-boot for ${board}"

	make -C "${UBOOT_SRC}" BL31="${RKBIN_BIN}/${BL31}" ROCKCHIP_TPL="${RKBIN_BIN}/${ROCKCHIP_TPL}" -j8
}

install_binaries()
{
	log "Installing u-boot binaries for ${board} into ${BOARD_DIR}/"

	cp "${UBOOT_SRC}/u-boot.itb" "${UBOOT_SRC}/idbloader.img" "${BOARD_DIR}/"
}

for board ; do
	clean_env
	source_env "$board"
	clean_uboot
	configure_uboot
	build_uboot
	install_binaries
done

