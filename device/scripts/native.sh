# native.sh: Install a .tar.gz packaged native Linux distribution. To be
# sourced by the main SmackMe script.
# Will Castro <castrwilliam at gmail>

# install_native:
# $1: tarchive
# $2: LV name
# $3: LV size
install_native() {
	if [ ! -e /dev/store/$2-root ]; then
		echo "Creating root logical volume for $2." >&2
		lvm.static lvcreate -n $2-root -L ${3}M store
	fi

	echo "Formatting root filesystem for $2." >&2
	mkfs.ext3 /dev/store/$2-root 2>/dev/null
	mkdir /mnt/$2
	mount -t ext4 /dev/store/$2-root /mnt/$2
	echo "Complete." >&2

	echo "Extracting $2 tarchive. This may take upwards of 10 minutes." >&2
	echo "Please wait..." >&2
	gunzip -c $1 | tar -C /mnt/$2 -x 
	echo "Extraction complete." >&2
}

unsplit_native() {
	if [ ! -e /dev/store/$2-root ]; then
		echo "Creating root logical volume for $2." >&2
		lvm.static lvcreate -n $2-root -L ${3}M store
	fi

	echo "Formatting root filesystem for $2." >&2
	mkfs.ext3 /dev/store/$2-root 2>/dev/null
	mkdir /mnt/$2
	mount -t ext4 /dev/store/$2-root /mnt/$2
	echo "Complete." >&2

	partname=${1%.1}
	
	num=$(ls $partname.* | wc -l)

	echo "Extracting $num split tarchives for $2. This may take upwards of 10 minutes." >&2
	echo "Please wait..." >&2
	cat $partname.* | gunzip -c | tar -C /mnt/$2 -x 

	echo "Extraction complete." >&2
	rm -f $partname.[23456789]*
}
