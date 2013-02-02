# android.sh: Install Android on a set of logical volumes. To be sourced by the
# main SmackMe script.
# Will Castro <castrwilliam at gmail>

# install_android:
# $1: Zip file path
# $2: LV base name
# $3: System size
# $4: Data size
# $5: Cache size
install_android() {
	lvm.static lvcreate $2-system $3
	lvm.static lvcreate $2-data $4
	lvm.static lvcreate $2-cache $5

	mke2fs -t ext4 /dev/store/$2-system

	mke2fs -t ext4 /dev/store/$2-data
	mke2fs -t ext4 /dev/store/$2-cache

	mkdir /mnt/$2 /mnt/$2/system /mnt/$2/data /mnt/$2/cache
	mount -t ext4 /dev/store/$2-system /mnt/$2/system
	mount -t ext4 /dev/store/$2-data /mnt/$2/data
	mount -t ext4 /dev/store/$2-cache /mnt/$2/cache
	
	echo -n "Unzipping $1: " >&2

	unzip -d /mnt/$2 -o $1
	if [ $? -gt 0 ]; then 
		echo -n "FAILED" >&2
		return 1
	fi

	if [ ! -f /mnt/$2/system/etc/firmware/q6.mdt ]; then
		echo "Copying audio firmware..." >&2
		mkdir /firmware
		mount -t vfat /dev/mmcblk0p1 /firmware
		cp /firmware/image/q6.{b00,b01,b02,b03,b04,b05,mdt} /mnt/$2/system/etc/firmware/
	fi

	if [ -f /mnt/$2/moboot.splash.CyanogenMod.tga -a ! -f /boot/moboot.splash.$2.tga ]; then
		echo "installing splash image" >&2
		mv /mnt/$2/moboot.splash.CyanogenMod.tga /boot/moboot.splash.$2.tga
	fi

	echo "running update script" >&2
	# Thank you.
	cd /mnt/$2
	cat /mnt/$2/META-INF/com/google/android/updater-script | grep -v '^\(assert\)\|\(package_extract_.*\)\|\(^mount\)\|\(format\)\|\(run_program\)\|\(^umount\)\|\(^unmount\)\|\(show_progress\)\|\(ui_print\)\|\(^delete\)' | sed 's/^seterror_perm(\([0123456789]\+\), \+\([0123456789]\+\), \([0123456789]\+\), "\(.*\)");/chown \1:\2 \4 ; chmod \3 \4/' | sed 's/^set_perm_recursive(\([0123456789]\+\), \+\([0123456789]\+\), \([0123456789]\+\), \([0123456789]\+\), "\(.*\)");/chown -R \1:\2 \5 ; chmod -R \3 \5 ; find \5 -type f -exec chmod \4 {} \\;/' | sed 's/,$/ \\/' | sed 's/^symlink(\("[A-z\.\-]*"\), /export LINK=\1 ; for i in /' | sed 's/\("\)\|\(,\)//g' | sed 's/);/ ; do ln -s $LINK $i ; done/' | sed 's/\/system/system/g' > /mnt/$2/updatescript
	bash /mnt/$2/updatescript
	rm -rf /mnt/$2/META-INF
	rm /mnt/$2/updatescript
	
	if [ -f /mnt/$2/boot.img ]; then
		cd /mnt/$2
		st "patching init.tenderloin.rc in uImage"
		cp /mnt/$2/boot.img /media/sminstall/kern/orig/uImage.$2
		uextract boot.img 
		mv ramdisk.img Ramdisk.gz
		gunzip Ramdisk.gz
		mkdir extracted
		cd extracted
		cpio -i < ../Ramdisk
		# Replace LVM names in the init.rc.
		sed -i -e "s/cm-data/$2-data/" -e "s/cm-cache/$2-cache/" \
			-e "s/cm-system/$2-system/" init.tenderloin.rc
		find . | cpio -o --format=newc | gzip > ../ramdisk.img
		cd ..
		mkimage -A arm -O linux -T kernel -C none -a 0x40208000 -e 0x40208000 \
			-n "kernel image" -d kernel.img ukernel.img 
		mkimage -A arm -O linux -T ramdisk -C none -a 0x60000000 -e 0x60000000 \
			-n "ramdisk image" -d ramdisk.img uramdisk.img 
		mkimage -A arm -O linux -T multi -C none -a 0x40208000 -e 0x40208000 \
			-n "multi image" -d ukernel.img:uramdisk.img uImage.$2 
		rm -f boot.img kernel.img Ramdisk ramdisk.img ukernel.img uramdisk.img 
		rm -rf extracted

		st "- installing modified uImage"
		cp /mnt/$2/uImage.$2 /media/sminstall/kern/mod
		cp /mnt/$2/uImage.$2 /boot
		if [ $? -gt 0 ]; then
			echo "Failed to copy the uImage! Most likely you are out of space on /boot." >&2
			echo "Check that and reinvoke me as you wish. Removing the partially copied kernel." >&2
			rm /boot/uImage.$2
			return 1
		fi
	fi # if boot.img exists

	return 0
}

# install_gapps:
# $1: ZIP file
# $2: LV base name
install_gapps() {
	[ -f /mnt/$2/system/build.prop ] && return 3
	unzip -d /mnt/$2 -o $1
	return 0
}


