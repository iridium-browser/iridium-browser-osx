#!/bin/bash

# Iridium browser OSX source patching script
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


# This script applies all necessary patches and prepares Iridium for building.
# This script will clone Chromium src if necesary.

# !!!WARNING: This script should be run only from its directory,
# i.e. '/path/to/iridium/iridium-browser-osx/', at the same level as you have or expect to have '/path/to/iridium/src'.
# If you run it from other directory results are undefined
# and if you have .gclient file nearby you can mess up the project of this nearby .gclient.


set -eu

# Changes section
CHROMIUM_GIT="https://chromium.googlesource.com/chromium/src.git"
CHROMIUM_SRC_DIR="src"
# This is Chromium for 51.0.2704.22
# You can lookup commit hashes for versions at https://omahaproxy.appspot.com/
CHROMIUM_VERSION="768952f4c30de3cad38c00449f22bd184dc61e77"

IRIDIUM_PATCH_FILE="ir-51.0.x-51.0.2704.22.diff"

# This is a patch file of changes which were not yet synced with main Iririum repo
IRIDIUM_UNSYNCED_PATCH_FILE="ir-unsynced.diff"

IRIDIUM_VERSION_PATCH_FILE="ir-version.diff"
IRIDIUM_BUILD_TWEAKS_PATCH="ir-build_tweaks.diff"
IRIDIUM_DEPENDENCIES_PATCH="ir-dependencies.diff"

# This patch should be applied after IRIDIUM_PATCH_FILE.
# This patch should be edited manually to setup Apple development team ID or this script will try to edit the patch if you pass teemID argument.
IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH="ir-osx-sandbox-apple-dev.diff"
IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH_TO_CHANGE="ir-osx-sandbox-apple-dev.diff.in"

# Please keep in mind that actual resources names like app.icns
# come from Chromium sources and that is why we should have
# the same names in our IRIDIUM_RESOURCES_DIR.
IRIDIUM_RESOURCES_DIR="resources"

# Do not modify anything after this comment unless you really know what you are doing.
# ----------------------------------------------------------------------------

# redefine pushd and popd in order not to show output in stdout
pushd() { builtin pushd "$@" > /dev/null; }
popd() { builtin popd > /dev/null; }


print_usage() {
	echo "Usage: iridium-osx-patch [-m|--mode <iad/nosign>] [-t|--team-id <teamID>]"
	echo " -m|--mode:"
	echo "     'iad' = Identified Apple Developer (outside Mac App Store) build"
	echo "     'nosign' = no signature"
	echo " -t|--team-id:"
	echo "     Apple developer team ID for sandboxing."
	echo "     If build mode is 'iad' this argument is required."
	echo "     You can find your team ID in developer.apple.com"
}


while [[ $# > 0 ]]
do
	key="$1"

	case $key in
		-m|--mode)
			BUILD_MODE="$2"
			shift
			;;
		-t|--team-id)
			TEAM_ID="$2"
			shift
			;;
		-h|--help)
			print_usage
			exit 0
			;;
		*)
			echo "No arguments were given or incorrect arguments were given."
			print_usage
			exit 1
		;;
	esac

	shift
done


# Check if build mode is 'mas' or 'iad' and there is osx-sandbox-patch
if [ "${BUILD_MODE}" == "mas" ] || [ "${BUILD_MODE}" == "iad" ]; then

	if [ ! -e "patches/$IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH" ] && [ -z "${TEAM_ID}" ]; then
		echo "Please give team-id argument or manually edit $IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH_TO_CHANGE to create $IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH with correct Team ID"
		exit 1
	else

		if [ ! -z "${TEAM_ID}" ]; then
			echo "Replacing placeholder TeamID with $TEAM_ID"
			sed -e s/APPLE_TEAM_ID_TO_REPLACE/"$TEAM_ID"/g "patches/$IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH_TO_CHANGE" > "patches/$IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH"
		fi

	fi

fi


echo "Starting iridium-osx-patch.sh script in $PWD"

# install depot_tools
pushd .
cd ..
if ! hash gclient 2>/dev/null && [ ! -d "depot_tools" ]; then
	echo "Installing depot_tools..."
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
export PATH=$PATH:`pwd`/depot_tools
popd

# prepare chromium src for patching
pushd .
# cd one level up to correctly clone/work with sorces
cd ..
if [ ! -d "$CHROMIUM_SRC_DIR" ]; then
	# clone chromium src if it is not there already
	echo "Cloning Chromium sources..."
	git clone "$CHROMIUM_GIT" "$CHROMIUM_SRC_DIR"

	GCLIENT_FILE="solutions = [
  		{
    		\"managed\": False,
    		\"name\": \"src\",
    		\"url\": \"https://chromium.googlesource.com/chromium/src.git\",
    		\"custom_deps\": {},
    		\"deps_file\": \".DEPS.git\",
    		\"safesync_url\": \"\",
  		},
	]"
	# echo "$GCLIENT_FILE"
	echo "$GCLIENT_FILE" > .gclient
else
	cd "$CHROMIUM_SRC_DIR"

	echo "Fetching update for Chromium sources..."

	git fetch

	# revert all dependencies changes, this should efectively make all dependencies clean
	gclient revert --nohooks

	cd ..
fi
# go to src ('/path/to/chromium/src')
cd "$CHROMIUM_SRC_DIR"
echo "Checking out upstream Chromium version"
# reset repo to needed version
git checkout -f "$CHROMIUM_VERSION"

echo "Synching dependencies..."
# resync all other dependencies with correct version
gclient sync -R --nohooks --with_branch_heads
# go back to script dir
popd



# apply general Iridium patch
pushd .
cp -f "patches/$IRIDIUM_PATCH_FILE" "../$CHROMIUM_SRC_DIR/"
cd "../$CHROMIUM_SRC_DIR"
patch -l -p1 < "$IRIDIUM_PATCH_FILE"
rm $IRIDIUM_PATCH_FILE
# go back to script dir
popd



# apply unsynced patch if exists
if [[ ! -z $IRIDIUM_UNSYNCED_PATCH_FILE ]] && [ -e "patches/$IRIDIUM_UNSYNCED_PATCH_FILE" ]; then
	pushd .
	cp -f "patches/$IRIDIUM_UNSYNCED_PATCH_FILE" "../$CHROMIUM_SRC_DIR/"
	cd "../$CHROMIUM_SRC_DIR"
	patch -l -p1 < "$IRIDIUM_UNSYNCED_PATCH_FILE"
	rm $IRIDIUM_UNSYNCED_PATCH_FILE
	# go back to script dir
	popd
fi



# apply osx sandboxing patch if exist
if [ -e "patches/$IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH" ]; then
	echo "Applying OSX sandboxing patch"
	pushd .
	cp -f "patches/$IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH" "../$CHROMIUM_SRC_DIR/"
	cd "../$CHROMIUM_SRC_DIR"
	patch -l -p1 < "$IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH"
	rm $IRIDIUM_OSX_SANDBOX_APPLE_DEVELOPER_RELATED_PATCH
	# go back to script dir
	popd
fi


# apply build tweaks patch if exists
if [[ ! -z $IRIDIUM_BUILD_TWEAKS_PATCH ]] && [ -e "patches/$IRIDIUM_BUILD_TWEAKS_PATCH" ]; then
	pushd .
	cp -f "patches/$IRIDIUM_BUILD_TWEAKS_PATCH" "../$CHROMIUM_SRC_DIR/"
	cd "../$CHROMIUM_SRC_DIR"
	patch -l -p1 < "$IRIDIUM_BUILD_TWEAKS_PATCH"
	rm $IRIDIUM_BUILD_TWEAKS_PATCH
	# go back to script dir
	popd
fi



# apply app bundle version patch if exists
if [[ ! -z $IRIDIUM_VERSION_PATCH_FILE ]] && [ -e "patches/$IRIDIUM_VERSION_PATCH_FILE" ]; then
	pushd .
	cp -f "patches/$IRIDIUM_VERSION_PATCH_FILE" "../$CHROMIUM_SRC_DIR/"
	cd "../$CHROMIUM_SRC_DIR"
	patch -l -p1 < "$IRIDIUM_VERSION_PATCH_FILE"
	rm $IRIDIUM_VERSION_PATCH_FILE
	# go back to script dir
	popd
fi



# apply dependencies patch if exists
if [[ ! -z $IRIDIUM_DEPENDENCIES_PATCH ]] && [ -e "patches/$IRIDIUM_DEPENDENCIES_PATCH" ]; then
	pushd .
	cp -f "patches/$IRIDIUM_DEPENDENCIES_PATCH" "../$CHROMIUM_SRC_DIR/"
	cd "../$CHROMIUM_SRC_DIR"
	patch -l -p1 < "$IRIDIUM_DEPENDENCIES_PATCH"
	rm $IRIDIUM_DEPENDENCIES_PATCH
	# go back to script dir
	popd
fi



# replace Chromium app icon with Iridium app icon
pushd .
echo "Replacing application icons"
cp -f "$IRIDIUM_RESOURCES_DIR/app.icns" "../$CHROMIUM_SRC_DIR/chrome/app/theme/chromium/mac/"
cp -f "$IRIDIUM_RESOURCES_DIR/document.icns" "../$CHROMIUM_SRC_DIR/chrome/app/theme/chromium/mac/"
# go back to script dir
popd



# create build settings files after patch
pushd .
cd "../$CHROMIUM_SRC_DIR"
gclient runhooks
# go back to script dir
popd



# enable 64bit build
pushd .
cd "../$CHROMIUM_SRC_DIR"
build/gyp_chromium -Dtarget_arch=x64 -Dhost_arch=x64
# go back to script dir
popd


# clean up localizations
python trim_xtb.py -d "../$CHROMIUM_SRC_DIR/chrome/app/resources/"



# print message that Iridium is ready to be built
echo "You can now run: ninja -C out/Release chrome in ../src/"


