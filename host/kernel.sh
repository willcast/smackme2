#!/bin/bash 	
# SmackMe 2.0 kernel compiler script
# Will Castro <castrwilliam at gmail>

# NOT YET FINISHED.
exit 0

selection=$(zenity --title 'SmackMe Kernel Creator v2.0' --list \
	--text='Select an Operating System to build the kernel for:' \
	--height=512 --width=512 \
	--column='Short Name' --column 'Long Name'  --column 'kexec Capable' \
	arch 'Arch Linux ARM' yes \
	cm7a2 'CyanogenMod 7 (alpha < 3)' yes \
	cm7a3 'CyanogenMod 7 (alpha 3.x)' yes \
	cm9 'CyanogenMod 9 (with camera)' yes \
	cm9bk 'CM9 Bricked Kernel (Alpha 2, no camera)' yes \
	cm10 'CyanogenMod 10 (with camera)' yes \
	froyo 'Qualcomm Froyo (castrwilliam)' yes \
	ubuntu 'Ubuntu 12.04 and newer' yes \
	uexp 'Ubuntu (castrwilliam unstable kernel)' yes \
	);

case selection in
arch|fedora|slack|ubuntu )
	url='
	srcurl='git://github.com/BodenM/hp-kernel-tenderloin-ubuntu'
	sbranch='Ubuntu'
	;;
cm7a2 )
	srcurl='git://github.com/jcsullins/hp-kernel-tenderloin'
	srcbranch='gingerbread'
	;;
cm7a3|froyo )
	srcurl='git://github.com/jcsullins/hp-kernel-tenderloin'
	srcbranch='ics'
	srctag='944535287d7c580895cdc1694f44563b87755fda'
	;;
cm9 )
	srcurl='git://github.com/jcsullins/hp-kernel-tenderloin'
	srcbranch='ics'
	;;
cm10 )
	srcurl='git://github.com/jcsullins/hp-kernel-tenderloin'
	srcbranch='jellybean'
	;;

# For when I patch with Dorregaray's patch and distribute:
# froyo )
#	srcurl='github.com/willcast/ubuntu-kernel-tenderloin'
#	srcbranch='froyo'
#	;;
		
uexp )
	srcurl='git://github.com/willcast/ubuntu-kernel-tenderloin'
	srcbranch='jellybean'
	;;
esac

clear
mkdir -p ~/smackme2/$selection

git clone git://github.com/jcsullins/moboot ~/smackme2/moboot
cd ~/smackme2/moboot/tools
gcc -o uimage-extract -lz uimage-extract.c
cd ~/smackme2
moboot/tools/uimage-extract $uimage
rm kernel.img
mv ramdisk.img ramdisk.gz
gunzip ramdisk.gz
mkdir ramdisk-ext
cd ramdisk-ext
cpio -i < ../ramdisk
# For Android, replace INIT with "init.tenderloin.rc".
# For Ubuntu, just use "init."
# I'm not sure about Arch/Debian.
# Slackware/Fedora will have ramdisks exactly like Ubuntu 12.10 Final.
# Use the OPSYS name you used in Step 1.
# Also as with Step 1, run the command 3x for Android with each part's name.
# (system, data, cache), or 1x for native Linux with LVNAME=root.
sed -i -e "s/cm-data/OPSYS-LVOL/" INITFILE
find . | cpio -o --format=newc > ../ramdisk-ext
cd ..
lzma ramdisk-ext
cp ramdisk.ext initrd.img-OPSYS
# Kernel repos / branches to use:
# Ubuntu: git://github.com/BodenM/hp-kernel-tenderloin-ubuntu / Ubuntu
# Arch/Debian (or Android 4.2): search/ask in our forums.
# Android 2.2 - 4.0: git://github.com/jcsullins/hp-kernel-tenderloin
# 2.2 branch is actually "ics", but make sure to get revision 94453528
# (from December 14, 2011.) 2.3 is different depending on which alpha leve.
# Before a3.0, you should get the latest from "gingerbread", but a3.0/a3.5 both
# only boot with the same ics revision as 2.2 does. ICS and Jellybean 4.1 use 
# their respective branches.
git clone KERNEL_REPO kernel -b KERNEL_BRANCH 

cd kernel

# You'll need to download the patch from my first post. It makes your compiled
# kernel work with kexec.
patch -p2 < PATCH_FROM_MY_FIRST_POST
# DEFCONFIG: Android uses tenderloin_android_defconfig, native Linux uses
# tenderloin_defconfig.
make DEFCONFIG
# IMGTYPE: For kexec, use zImage, for moboot, use uImage.
# CORES is the number of theads your CPU has. "lscpu" comes in handy here if you
# don't know.
make -jTHREADS IMGTYPE
cd ..
cp kernel/arch/arm/boot/zImage ../vmlinuz-OPSYS

# Only execute these if you DON'T plan to use kexec to boot your new OS (i.e.
# you want a Moboot uImage, not seperate zImage and ramdisk.)
mkimage -A arm -O linux -T ramdisk -C none -a 0x6000000 -e 0x60000000
mkimage -A arm -O linux -T multi -C none -a 0x40208000 -e 0x40208000 \
	kernel/arch/arm/boot/uImage:uRamdisk uImage.OPSYS  
	
	
# Remember to install the files you created.
# Moboot uses the uImage.OPSYS, and kexec uses vmlinuz-OPSYS and initrd-OPSYS.
# using the appropriate transfer method (I use SSH to native Ubuntu)
