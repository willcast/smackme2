smackme2
========

Scripts for the SmackMe2 installer on HP TouchPad!

Chdir to 'host' and run 'testbuild.sh' with a plugged-in, recovery-mode
TP to test. Make a file on in the sminstall folder (see original forum post) 
with the name 'debugmode' for a dry run.

If you like the built uImage, it's under the 'device' directory as 'uImage.SmackMe2'.

The build script needs a working gcc setup and the development files for zlib.
If you don't use sudo you'll need to be root and remove the sudo prefixes from certain lines of the script.
Obviously you'll need novacom/novaterm to test this. SmackMe2 was developed on Ubuntu 12.10 amd64.

