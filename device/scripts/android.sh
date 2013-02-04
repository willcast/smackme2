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
	if [ ! -e /dev/store/$2-cache ]; then
		echo "Creating logical volumes for $2." >&2
		lvm.static lvcreate $2-system ${3}M
		lvm.static lvcreate $2-data ${4}M
		lvm.static lvcreate $2-cache ${5}M
	fi

	echo "Creating filesystems for $2." >&2
	mke2fs -t ext4 /dev/store/$2-system 2>/dev/null
	mke2fs -t ext4 /dev/store/$2-data 2>/dev/null
	mke2fs -t ext4 /dev/store/$2-cache 2>/dev/null

	mkdir /mnt/$2 /mnt/$2/system /mnt/$2/data /mnt/$2/cache
	mount -t ext4 /dev/store/$2-system /mnt/$2/system
	mount -t ext4 /dev/store/$2-data /mnt/$2/data
	mount -t ext4 /dev/store/$2-cache /mnt/$2/cache
	
	echo "Unzipping $2 zipfile, $1: " >&2
	( cd /mnt/$2 && unzip -qo $1 )
	if [ $? -gt 0 ]; then 
		echo "Failed to unzip." >&2
		error
	fi
	echo "Unzip complete." >&2

	if [ ! -f /mnt/$2/system/etc/firmware/q6.mdt ]; then
		echo "Copying audio firmware..." >&2
		mkdir /firmware
		mount -t vfat /dev/mmcblk0p1 /firmware
		cp /firmware/image/q6.{b00,b01,b02,b03,b04,b05,mdt} /mnt/$2/system/etc/firmware/
	fi

	if [ -f /mnt/$2/moboot.splash.CyanogenMod.tga -a ! -f /boot/moboot.splash.$2.tga ]; then
		echo "Installing Moboot splash image" >&2
		mv /mnt/$2/moboot.splash.CyanogenMod.tga /boot/moboot.splash.$2.tga
	fi

	echo "Running updater script." >&2
	# Thank you.
	cd /mnt/$2
	# Direct lift of evil, evil sequence of filters.
	cat META-INF/com/google/android/updater-script | grep -v '^\(assert\)\|\(package_extract_.*\)\|\(^mount\)\|\(format\)\|\(run_program\)\|\(^umount\)\|\(^unmount\)\|\(show_progress\)\|\(ui_print\)\|\(^delete\)' | sed 's/^set_perm(\([0123456789]\+\), \+\([0123456789]\+\), \([0123456789]\+\), "\(.*\)");/chown \1:\2 \4 ; chmod \3 \4/' | sed 's/^set_perm_recursive(\([0123456789]\+\), \+\([0123456789]\+\), \([0123456789]\+\), \([0123456789]\+\), "\(.*\)");/chown -R \1:\2 \5 ; chmod -R \3 \5 ; find \5 -type f -exec chmod \4 {} \\;/' | sed 's/,$/ \\/' | sed 's/^symlink(\("[A-z\.\-]*"\), /export LINK=\1 ; for i in /' | sed 's/\("\)\|\(,\)//g' | sed 's/);/ ; do ln -s $LINK $i ; done/' | sed 's/\/system/system/g' > /mnt/$2/updatescript
	bash /mnt/$2/updatescript 2>/dev/null
	rm -rf /mnt/$2/META-INF
	rm /mnt/$2/updatescript
	
	if [ -f /mnt/$2/boot.img ]; then
		cd /mnt/$2
		echo "patching init.tenderloin.rc in uImage" >&2
		cp /mnt/$2/boot.img /media/sminstall/kern/orig/uImage.$2
		uextract /mnt/$2/boot.img 2>/dev/null
		mv ramdisk.img Ramdisk.gz
		gunzip Ramdisk.gz
		mkdir extracted
		cd extracted
		cpio -i < ../Ramdisk 2>/dev/null
		# Replace LVM names in the init.rc.
		sed -i -e "s/cm-data/$2-data/" -e "s/cm-cache/$2-cache/" \
			-e "s/cm-system/$2-system/" init.tenderloin.rc
		find . | cpio -o --format=newc | gzip > ../ramdisk.img 2>/dev/null
		cd ..
		mkimage -A arm -O linux -T kernel -C none -a 0x40208000 -e 0x40208000 \
			-n "kernel image" -d kernel.img ukernel.img 
		mkimage -A arm -O linux -T ramdisk -C none -a 0x60000000 -e 0x60000000 \
			-n "ramdisk image" -d ramdisk.img uramdisk.img 
		mkimage -A arm -O linux -T multi -C none -a 0x40208000 -e 0x40208000 \
			-n "multi image" -d ukernel.img:uramdisk.img uImage.$2 
		rm -f boot.img kernel.img Ramdisk ramdisk.img ukernel.img uramdisk.img 
		rm -rf extracted

		echo "Installing modified uImage in kern/mod." >&2
		cp /mnt/$2/uImage.$2 /media/sminstall/kern/mod

		if [ ! -e /media/sminstall/kexec-$2.tar ]; then
			echo "no kexec package found - installing uImage in /boot." >&2
			cp /mnt/$2/uImage.$2 /boot >/dev/null
			if [ $? -gt 0 ]; then
				echo "Error installing kernel in /boot, you're likely out of space." >&2
				echo "$2 will be *un-bootable* until you find a kexec package, or free up" >&2
				echo "space in /boot (/dev/mmcblk0p13) and manually install the kernel from" >&2
				echo "the ZIP file in the sminstall/finished folder of your media partition." >&2
				rm -f /boot/uImage.$2
			fi
		else
			echo "kexec package found - uImage skipped for $2" >&2
		fi
	fi # if boot.img exists

	return 0
}

# install_gapps:
# $1: ZIP file
# $2: LV base name
install_gapps() {
	if [ ! \( -f /mnt/$2/system/etc/build.prop -o -f /mnt/$2/system/build.prop \) ]; then
		mkdir /mnt/$2 /mnt/$2/system /mnt/$2/data /mnt/$2/cache
		mount -t ext4 /dev/store/$2-system /mnt/$2/system 
		mount -t ext4 /dev/store/$2-data /mnt/$2/data 
		mount -t ext4 /dev/store/$2-cache /mnt/$2/cache 
	fi

	[ -f /mnt/$2/system/etc/build.prop ] && return 3
	echo "Unzipping Google Apps ZIP for $2, $1" >&2
	( cd /mnt/$2 && unzip -oq $1 )
	echo "Unzip complete." >&2

	echo "Running updater script." >&2
	echo "cd /mnt/$2" > /mnt/$2/updatescript
	cat META-INF/com/google/android/updater-script | grep -v '^\(assert\)\|\(package_extract_.*\)\|\(^mount\)\|\(format\)\|\(run_program\)\|\(^umount\)\|\(^unmount\)\|\(show_progress\)\|\(ui_print\)\|\(^delete\)' | sed 's/^set_perm(\([0123456789]\+\), \+\([0123456789]\+\), \([0123456789]\+\), "\(.*\)");/chown \1:\2 \4 ; chmod \3 \4/' | sed 's/^set_perm_recursive(\([0123456789]\+\), \+\([0123456789]\+\), \([0123456789]\+\), \([0123456789]\+\), "\(.*\)");/chown -R \1:\2 \5 ; chmod -R \3 \5 ; find \5 -type f -exec chmod \4 {} \\;/' | sed 's/,$/ \\/' | sed 's/^symlink(\("[A-z\.\-]*"\), /export LINK=\1 ; for i in /' | sed 's/\("\)\|\(,\)//g' | sed 's/);/ ; do ln -s $LINK $i ; done/' | sed 's/\/system/system/g' >> /mnt/$2/updatescript 2>/dev/null
	bash /mnt/$2/updatescript 2>/dev/null
	rm -rf /mnt/$2/META-INF
	rm -f /mnt/$2/updatescript

	return 0
}


