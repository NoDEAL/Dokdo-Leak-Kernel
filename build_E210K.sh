# Made By Gwon Hyeok
#!/bin/bash
#clean ramfs folder and workdir

if [ '' = $1 ]
then
    echo "usage: ./build_E210K.sh [number of threads]"
fi

rm -rf tmp_Ramfs
rm -rf workdir
export HERE_DIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export CROSS_COMPILE=~/toolchains/arm-cortex_a8-linux-gnueabi-linaro_4.7.4-2013.10/bin/arm-cortex_a8-linux-gnueabi-
CROSS_COMPILE_STRIP=/opt/arm-eabi-4.4.3/bin/arm-eabi-strip

# Move Ramfs
mkdir tmp_Ramfs
cp -r $HERE_DIR/Ramdisk/SHV-E210K $HERE_DIR/tmp_Ramfs/SHV-E210K

# Build Start
export ARCH=arm
make E210K_defconfig
nice -n 10 make -j$1 || exit 1
echo "del original modules"
find tmp_Ramfs/SHV-E210K/ -name 'empty_dir' -exec rm -rf {} \;
rm -rf tmp_Ramfs/SHV-E210K/lib/modules/*.ko
find -name '*.ko' -exec cp -av {} tmp_Ramfs/SHV-E210K/lib/modules/ \;
$CROSS_COMPILE_STRIP --strip-unneeded tmp_Ramfs/SHV-E210K/lib/modules/*

find tmp_Ramfs/SHV-E20K | fakeroot cpio -H newc -o > ramdisk.cpio 2>/dev/null

gzip -9 ramdisk.cpio
nice -n 10 make -j$1 zImage || exit 1
./Ramdisk/mkbootimg --kernel arch/arm/boot/zImage --ramdisk ./ramdisk.cpio.gz --board smdk4x12 --base 0x10000000 --pagesize 2048 --ramdiskaddr 0x11000000 -o boot.img
mkdir workdir
mv boot.img workdir/
cp -r Ramdisk/META-INF workdir/
cd workdir
zip -9r 4.2.2_Stock_Kernel_SHV-E210K.zip *
cd -
mv workdir/4.2.2_Stock_Kernel_SHV-E210K.zip ./
echo Build Finish
