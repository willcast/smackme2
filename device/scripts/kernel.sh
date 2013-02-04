 # kernel.sh: Install various kernel and ramdisk permutations. Sourced by the
# main SmackMe script.
# Will Castro <castrwilliam at gmail>

# install_kexec: 
# $1: kexec tarchive 
# 
# these tarchives are always uncompressed and contain the following files:
# vmlinuz-<name> = the zImage to boot
# initrd.img-<name> = the initrd to boot
# boot.cfg = kexecboot boot.cfg file. 
# smackme.cfg = installation parameters:
#     - ROOTDEV=/dev/store/<lvname> the root device to install this on.

install_kexec() {
	mkdir -p /tmp/kexec-ext
	( cd /tmp/kexec-ext && tar -xf $1 )
	lvname=$(grep 'ROOTDEV=' /tmp/kexec-ext/smackme.cfg | cut -c9-);
	echo "kexec lvname = $lvname" >&2

	mtpt=$(grep "$lvname" /proc/mounts | awk '{print $2}')
	if [ -z "$mtpt" ]; then
		# We've been called on an unmounted OS, which likely means that the OS
		# that this file belongs to has already been installed in a previous
		# session.	
		tmpmnt=tmpmnt
		mtpt=/mnt/$(basename $lvname)
		mkdir -p $mtpt
		mount -t ext4 $lvname $mtpt
	fi
	echo "kexec mtpt = $mtpt" >&2

	mkdir -p $mtpt/boot
	cp /tmp/kexec-ext/* $mtpt/boot/

	rm -rf /tmp/kexec-ext

	[ ! -z "$tmpmnt" ] && umount $mtpt
	return 0
}

# install_uimage
# $1: uImage (to copy to /boot)
#
# The reason that I don't simply cp them in the main script is so I can check
# for free space before doing so. moboot seems to be unreliable when there is
# no free space in /dev/mmcblk0p13 (normal /boot.)
install_uimage() {
	freespc=$(df -k /boot | tail -1 | awk '{print $4}')
	echo "free space on /boot = $freespc KiB" >&2
	usage=$(du -k $1 | awk '{print $1     	}')
	echo "disk usage of $1: $usage KiB" >&2

	if [ $usage -lt $freespc ]; then
		cp $1 /boot/
	else
		echo "insufficient free space for uImage $1" >&2
		return 1
	fi
}

