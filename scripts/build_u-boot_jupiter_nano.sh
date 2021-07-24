#!/bin/bash

# Build variables
patch_dir="$(pwd)/patches/u-boot"
output_dir="$(pwd)/output"
build_dir="${output_dir}/build"
uboot_bin="${output_dir}/u-boot"
uboot_dir="${build_dir}/u-boot"

# core count for compiling with -j
cores=$(( $(nproc) * 2 ))

release="${release:-v2019.07}"

# specify compiler 
CC="$(pwd)/tools/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-"
#CC=arm-none-eabi-

# Make the u-boot output dir
if [ ! -d "${uboot_bin}" ]; then
    echo "making output dir."
    mkdir -p "${uboot_bin}"
fi

# clone u-boot
if [ ! -d "${build_dir}/u-boot" ]; then
    git -C ${build_dir} clone https://github.com/u-boot/u-boot
    git -C ${uboot_dir} checkout ${release} -b tmp

    echo "patching.."

    cp patches/u-boot/at91-sama5d27_jupiter_nano.dts ${uboot_dir}/arch/arm/dts/
    cp patches/u-boot/sama5d27_jupiter_nano_mmc_defconfig ${uboot_dir}/configs/
    patch -d ${uboot_dir} -p1 < patches/u-boot/jupiter-nano-fixes-linux.patch 

    echo "patches complete.."
fi

echo "starting u-boot build.."
#ARCH=arm CROSS_COMPILE=${CC} make -j"${cores}" -C ${uboot_dir} distclean
ARCH=arm CROSS_COMPILE=${CC} make -j"${cores}" -C ${uboot_dir} sama5d27_jupiter_nano_mmc_defconfig
ARCH=arm CROSS_COMPILE=${CC} make -j"${cores}" -C ${uboot_dir} 
cp -v ${uboot_dir}/u-boot.bin ${uboot_bin}

echo "finished building u-boot"
