#!/bin/sh
# testbuild.sh: Build and memboot a SmackMe2 uImage.
# Will Castro <castrwilliam at gmail>

cd ../device

if [ ! -e ../tools/uimage-extract ]; then
	cd ../tools
	gcc -o uimage-extract uimage-extract.c -lz
	cd ../device
fi

../tools/uimage-extract uImage.orig
cp ramdisk.img ramdisk.gz
rm -f ramdisk
gunzip ramdisk.gz
mkdir -p ext

echo "This shell script requires sudo access to mount the initrd and operate"
echo "on its files. Currently, it hasn't been converted to use an initramfs."

sudo mount -o loop -t ext2 ramdisk ext/
sudo rm -f ext/etc/init.d/S90partition ext/etc/init.d/S99initialinstall
sudo cp S99smackme ext/etc/init.d/
sudo chmod 755 ext/etc/init.d/S99smackme
sudo mkdir -p ext/etc/scripts
sudo cp scripts/*.sh ext/etc/scripts/
sudo chmod 755 ext/etc/scripts/*

sudo umount ramdisk
rm -f ramdisk.lzma
lzma -e ramdisk
mkimage -A arm -O linux -T kernel -C none -a 0x40208000 -e 0x40208000 \
	-n 'SmackMe2 kernel' -d kernel.img uKernel

mkimage -A arm -O linux -T ramdisk -C none -a 0x60000000 -e 0x60000000 \
	-n 'SmackMe2 initramfs' -d ramdisk.lzma uRamdisk

mkimage -A arm -O linux -T multi -C none -a 0x40208000 -e 0x40208000 \
	-n 'SmackMe2 multi' -d uKernel:uRamdisk uImage.SmackMe2

echo "uImage is ready."
echo "Booting TP..."
novacom boot mem:// < uImage.SmackMe2

