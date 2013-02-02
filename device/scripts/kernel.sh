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
	tar -C /tmp/kexec-ext -xf $1
	lvname=$(grep 'ROOTDEV=' /tmp/kexec-ext/smackme.cfg | cut -c9-);
	[ -z "$SM_DEBUG" ] && echo "lvname = $lvname"
	mtpt=$(grep "$lvname" /proc/mounts | cut -d' ' -f2)
	[ -z $mtpt ] && return 3

	mkdir -p $mtpt/boot
	cp /tmp/kexec-ext/* $mtpt/boot/

	rm -r /tmp/kexec-ext

	return 0
}

# install_uimage
# $1: uImage (to copy to /boot)
#
# The reason that I don't simply cp them in the main script is so I can check
# for free space before doing so. moboot seems to be unreliable when there is
# no free space in /dev/mmcblk0p13 (normal /boot.)
install_uimage() {
	freespc="`df /boot | cut -d' ' -f4`"
	usage="`du $1 | cut -d ' ' -f1`"

	if [ $usage -lt $freespc ]; then
		cp $1 /boot
	else
		echo "insufficient free space for uImage $1" >&2
		return 1
	fi
}

