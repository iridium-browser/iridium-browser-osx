#!/bin/bash

# Iridium browser OSX signing script for outside of Mac App Store
# Copyright (C) 2015 struktur AG <opensource@struktur.de>

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA


#======= Don't change this part unless you know what you are doing =======

if [ -z "$6" ]
then
	echo
	echo "sign.sh usage: sign.sh signing_identity bundle_id bundle_version app_file_path output_name_without_.app output_dir"

	echo
	echo "Please keep in mind that bundle_version should correspond to the version you are setting in version patch!"

	echo
	echo "You can check your identities with: security -q find-identity"
	echo
	security -q find-identity
	echo
	exit 1
fi

IDENTITY=$1
BUNDLE_ID=$2
VERSION=$3
INPUT_FILE_PATH=$4
OUTPUT_FILE_NAME=$5
OUTPUT_DIR=$6


echo
echo "Iridium signing script"
echo
echo "	Please make sure you have setup signing and packaging identities in script correctly"
echo "	You can check your identities with: security -q find-identity -p codesigning -v"
echo
echo "	Your current settings:"
echo "	signing identity - $IDENTITY"
echo "	bundle id - $BUNDLE_ID"
echo "	version - $VERSION"
echo


echo
echo "Copying app"
rm -rf $OUTPUT_DIR/$OUTPUT_FILE_NAME.app
cp -p -a $INPUT_FILE_PATH $OUTPUT_DIR/$OUTPUT_FILE_NAME.app

echo
echo "Signing"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper.app"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper EH.app"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper NP.app"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/exif.so"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/ffmpegsumo.so"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/app_mode_loader.app"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Helpers/crashpad_handler"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Internet Plug-Ins/nacl_irt_x86_64.nexe"
codesign -s $IDENTITY "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/$OUTPUT_FILE_NAME Framework"

codesign -s $IDENTITY -i "$BUNDLE_ID" "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app"


# validate code signatures
echo
echo "Validating code signature and resources"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper EH.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper NP.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/exif.so"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/ffmpegsumo.so"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/app_mode_loader.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Helpers/crashpad_handler"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Internet Plug-Ins/nacl_irt_x86_64.nexe"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/$OUTPUT_FILE_NAME Framework"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app"

