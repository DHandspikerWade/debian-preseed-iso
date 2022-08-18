#!/bin/bash
# Based on https://wiki.debian.org/DebianInstaller/Preseed/EditIso
SOURCE_ISO="debian-11.4.0-amd64-netinst.iso"
INSTALL_TYPE="amd"


mkdir -p iso-cache

if [ ! -f iso-cache/$SOURCE_ISO ]; then
    echo "Downloading $SOURCE_ISO"
    curl -L "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$SOURCE_ISO" -o "iso-cache/$SOURCE_ISO"

    # TODO: check image hash
fi

mkdir -p build

# extract iso
echo "Extracting ISO contents"
bsdtar -C build -xf iso-cache/$SOURCE_ISO

# Add the preseed file
echo "Installing preseed"
chmod +w -R build/install.$INSTALL_TYPE/
gunzip build/install.$INSTALL_TYPE/initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F build/install.$INSTALL_TYPE/initrd
gzip build/install.$INSTALL_TYPE/initrd
chmod -w -R build/install.$INSTALL_TYPE/

# Redo md5 hashes
echo "Rebuilding hashes"
cd build
chmod +w md5sum.txt
find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt
chmod -w md5sum.txt
cd ..

chmod +w build/isolinux/isolinux.bin
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o preseed-$SOURCE_ISO build

# clean up
chmod +w -R build
rm -r build