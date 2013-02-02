# native.sh: Install a .tar.gz packaged native Linux distribution. To be
# sourced by the main SmackMe script.
# Will Castro <castrwilliam at gmail>

# install_native:
# $1: tarchive
# $2: LV name
# $3: LV size
install_native() {
	lvm.static lvcreate -n $2-root -L $3 store
	mkfs.ext3 /dev/store/$2
	mkdir /mnt/$2
	mount -t ext4 /dev/store/$2-root /$2/ubuntu

	echo "extracting $2 tarchive" >&2
	tar -C /mnt/$2 -xzf $1
}

