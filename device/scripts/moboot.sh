# moboot.sh: Install the moboot bootloader. To be sourced by the main SmackMe
# script.
# Will Castro <castrwilliam at gmail>

# $1: Zip file path

install_moboot() {
	echo "installing moboot" >&2
	mkdir /tmp/mbinst
	cd /tmp/mbinst
	unzip -o $1
	if [ -f /tmp/mbinst/uImage.moboot* ]; then	
		mv /tmp/mbinst/uImage.moboot* /boot/uImage.moboot
		if [ $? -gt 0 ]; then
			echo "MoBoot couldn't be copied to /boot." >&2
			echo "You may have run out of space on there." >&2 
			echo "Deleting the partially copied MoBoot." >&2
			rm /boot/uImage.moboot 
			error
		fi
		if [ ! -f /boot/moboot.splash.webOS.tga ]; then
			echo "installing webOS boot splash image for MoBoot" >&2
			zcat /boot/boot-images.tar.gz | tar -C /boot -xvf - BootLogo.tga
			mv /boot/BootLogo.tga /boot/moboot.splash.webOS.tga
		fi
		if [ ! -e /boot/uImage.webOS ]; then
			# /boot/uImage should already be a symlink to the webOS kernel.
			mv /boot/uImage /boot/uImage.webOS
			cd /boot 
			ln -s uImage.moboot uImage
		fi
		if [ ! -e /webos/etc/event.d/clear_moboot_nextboot ]; then
				echo "modifying your webOS install to work with MoBoot" >&2
				cp /root/clear_moboot_nextboot /webos/etc/event.d
		fi
	fi	

	return 0
}

