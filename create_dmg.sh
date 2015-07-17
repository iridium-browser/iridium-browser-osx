#!/bin/bash

# Iridium browser OSX dmg creation script
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


set -eu

#======= Change this part for proper signing =======

DMG_NAME="Iridium"
DMG_RESOURCE_DIR="resources/dmg"
VOLUME_ICNS_FILE="dmg_icon.icns"
VOLUME_BACKGROUND_IMAGE_FILE="dmg_background_02.png"
DMG_REPO="https://github.com/strukturag/create-dmg.git"
DMG_REPO_DIR="dmg_repo_creation_temp"

#======= Don't change this part unless you know what you are doing =======

# redefine pushd and popd in order not to show output in stdout
pushd() { builtin pushd "$@" > /dev/null; }
popd() { builtin popd > /dev/null; }


if [ -z "$2" ]
then
	echo
	echo "create_dmg.sh usage: create_dmg.sh app_file_path output_dir <dmg_name>"
	echo
	exit 1
else
	echo
	echo "Iridium dmg creation script"
	echo "Creating dmg in directory $2"
fi

if [[ $# == 3 ]]
then
	echo
	echo "Set $3 as dmg name"
	DMG_NAME=$3
fi

pushd .

cd $2
rm -rf $DMG_REPO_DIR
git clone $DMG_REPO $DMG_REPO_DIR
cd $DMG_REPO_DIR
mkdir -p dmg_source
cp -af "../../../$1" dmg_source/
cp "../../../$DMG_RESOURCE_DIR/$VOLUME_ICNS_FILE" .
cp "../../../$DMG_RESOURCE_DIR/$VOLUME_BACKGROUND_IMAGE_FILE" .


./create-dmg --volname "$DMG_NAME" \
--volicon "$VOLUME_ICNS_FILE" \
--background "$VOLUME_BACKGROUND_IMAGE_FILE" \
--window-pos 200 120 \
--window-size 480 540 \
--icon-size 128 \
--icon "$DMG_NAME.app" 240 100 \
--hide-extension "$DMG_NAME.app" \
--app-drop-link 240 360 \
"$DMG_NAME.dmg" \
dmg_source/


cp "$DMG_NAME.dmg" "../../../$2"

cd ..
rm -rf $DMG_REPO_DIR

popd
