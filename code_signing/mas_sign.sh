#!/bin/bash

# Iridium browser OSX signing script for Mac App Store
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


#======= Don't change this part unless you know what you are doing =======

if [ -z "$8" ]
then
	echo
	echo "mas_sign.sh usage: mas_sign.sh app_signing_id package_signing_id team_id bundle_id bundle_version app_file_path output_name_without_.app output_dir"

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
PACKAGE_IDENTITY=$2
TEAM_ID=$3
BUNDLE_ID=$4
VERSION=$5
INPUT_FILE_PATH=$6
OUTPUT_FILE_NAME=$7
OUTPUT_DIR=$8

echo
echo "Iridium signing script"
echo
echo "	Please make sure you have setup signing and packaging identities in script correctly"
echo "	You can check your identities with: security -q find-identity -p codesigning -v"
echo
echo "	Please also make sure you have setup the same TEAM_ID in content/browser/mach_broker_mac.mm"
echo "	as you are going to set in this script"

echo
echo "	Your current settings:"
echo "	signing identity - $IDENTITY"
echo "	packaging identity - $PACKAGE_IDENTITY"
echo "	team id - $TEAM_ID"
echo "	bundle id - $BUNDLE_ID"
echo "	bundle version - $VERSION"
echo



ENTITLEMENTS_P="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>$TEAM_ID.$BUNDLE_ID</string>
	</array>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
	<key>com.apple.security.personal-information.location</key>
	<true/>
	<key>com.apple.security.device.camera</key>
	<true/>
	<key>com.apple.security.device.microphone</key>
	<true/>
	<key>com.apple.security.device.bluetooth</key>
	<true/>
	<key>com.apple.security.print</key>
	<true/>
</dict>
</plist>
"

ENTITLEMENTS_C="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.inherit</key>
	<true/>
</dict>
</plist>
"



echo
echo "Copying app"
rm -rf $OUTPUT_DIR/$OUTPUT_FILE_NAME.app
cp -p -a $INPUT_FILE_PATH $OUTPUT_DIR/$OUTPUT_FILE_NAME.app


# echo "$ENTITLEMENTS_P"
echo "$ENTITLEMENTS_P" > /tmp/ent_parent
# echo "$ENTITLEMENTS_C"
echo "$ENTITLEMENTS_C" > /tmp/ent_child

echo
echo "Signing"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper.app"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper EH.app"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper NP.app"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/exif.so"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/ffmpegsumo.so"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/app_mode_loader.app"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/crash_report_sender.app"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/crash_inspector"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Versions/A/Internet Plug-Ins/PDF.plugin"
codesign -s $IDENTITY --entitlements /tmp/ent_child "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/$OUTPUT_FILE_NAME Framework"

codesign -s $IDENTITY -i "$BUNDLE_ID" --entitlements /tmp/ent_parent "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app"

# validate entitlements
echo
echo "Validating entitlements"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper.app/Contents/MacOS/$OUTPUT_FILE_NAME Helper"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper EH.app/Contents/MacOS/$OUTPUT_FILE_NAME Helper EH"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper NP.app/Contents/MacOS/$OUTPUT_FILE_NAME Helper NP"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/exif.so"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/ffmpegsumo.so"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/app_mode_loader.app"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/crash_report_sender.app"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/crash_inspector"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Versions/A/Internet Plug-Ins/PDF.plugin"
codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/$OUTPUT_FILE_NAME Framework"

codesign -dvvv --entitlements :- "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/MacOS/$OUTPUT_FILE_NAME"

# validate code signatures
echo
echo "Validating code signature and resources"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper EH.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Helper NP.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/exif.so"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Libraries/ffmpegsumo.so"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/app_mode_loader.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/crash_report_sender.app"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Resources/crash_inspector"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/Versions/A/Internet Plug-Ins/PDF.plugin"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app/Contents/Versions/$VERSION/$OUTPUT_FILE_NAME Framework.framework/$OUTPUT_FILE_NAME Framework"
spctl --assess -vvvv "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app"

echo
echo "Creating package"
productbuild --component "$OUTPUT_DIR/$OUTPUT_FILE_NAME.app" /Applications "$OUTPUT_DIR/$OUTPUT_FILE_NAME.pkg" --sign "$PACKAGE_IDENTITY"




