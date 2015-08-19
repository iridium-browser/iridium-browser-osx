#!/bin/bash

# Iridium browser OSX build script
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


# This script applies all necessary patches to prepare Iridium for building,
# builds Iridium and signs built product.

# !!!WARNING: This script should be run only from its directory,
# i.e. '/path/to/iridium/iridium-browser-osx/', at the same level as you have or expect to have '/path/to/iridium/src'.
# If you run it from other directory results are undefined
# and if you have .gclient file nearby you can mess up the project of this nearby .gclient.


set -eu

# !This has to correspond to CHROMIUM_SRC_DIR in iridium-osx-patch.sh!
CHROMIUM_SRC_DIR="src"

# Name of built application bundle, can vary depending on
# what is provided in patches
IRIDIUM_APP_BUNDLE_NAME="Iridium.app"
IRIDIUM_EXTRA_APP_BUNDLE_NAME="Iridium-extra.app"

# Output directory for finished builds. Has subdirs < mas, iad, nosign, tmp >
OUT_DIR="out_ir"

# Signing scripts path relative to parent dir of this script
SIGN_SCRIPTS_PATH="code_signing"

# Mac App Store signing script name
MAS_SIGN_SCRIPT="mas_sign.sh"

# Identified Apple Developer for outside of MAS signing script name
IAD_SIGN_SCRIPT="sign.sh"

# Find identity script
FIND_IDENTITY_SCRIPT="find_identity.py"

# Import identities script
IMPORT_IDENTITIES_SCRIPT="import_identities.sh"


# Do not modify anything after this comment unless you really know what you are doing.
# ----------------------------------------------------------------------------
MAS_SUBDIR="mas"
IAD_SUBDIR="iad"
IAD_EXTRA_SUBDIR="iad-extra"
NOSIGN_SUBDIR="nosign"
TMP_SUBDIR="tmp"

IRIDIUM_APP_NAME="Iridium"
IRIDIUM_EXTRA_APP_NAME="Iridium-extra"

# redefine pushd and popd in order not to show output in stdout
pushd() { builtin pushd "$@" > /dev/null; }
popd() { builtin popd > /dev/null; }


print_usage() {
	echo "Usage: build [-m|--mode <mas/iad/nosign>] [-p|--no-patching] [-b|--no-building] [-s|--no-packaging] [-i|--identities-dir] [-e|--extra-codecs]";
	echo " -m|--mode:"
	echo "     'mas' = Mac App Store build";
	echo "     'iad' = Identified Apple Developer (outside Mac App Store) build";
	echo "     'nosign' = no signature";
	echo " -i|--identities-dir:"
	echo "     Directory in which to search for signing/packaging identities to import."
	echo "     This should prompt for password to unlock keychain and for passphrases to import identities."
	echo "     If you want to import a lot of identities using default passphrase and giving the password to unlock keychain"
	echo "     you can use $SIGN_SCRIPTS_PATH/$IMPORT_IDENTITIES_SCRIPT directly."
}


prepare_for_mas() {
	echo "Preparing app for Mac App Store"
	pushd .

	mkdir -p "$OUT_DIR/$MAS_SUBDIR/$TMP_SUBDIR"

	cp "$SIGN_SCRIPTS_PATH/$MAS_SIGN_SCRIPT" "$OUT_DIR/$MAS_SUBDIR/$TMP_SUBDIR/"
	cp "$SIGN_SCRIPTS_PATH/$FIND_IDENTITY_SCRIPT" "$OUT_DIR/$MAS_SUBDIR/$TMP_SUBDIR/"
	if [ -e "$OUT_DIR/$MAS_SUBDIR/$TMP_SUBDIR/$IRIDIUM_APP_BUNDLE_NAME" ]; then
		rm -rf "$OUT_DIR/$MAS_SUBDIR/$TMP_SUBDIR/$IRIDIUM_APP_BUNDLE_NAME"
	fi
	cp -af "../$CHROMIUM_SRC_DIR/out/Release/$IRIDIUM_APP_BUNDLE_NAME" "$OUT_DIR/$MAS_SUBDIR/$TMP_SUBDIR/"
	cd "$OUT_DIR/$MAS_SUBDIR/$TMP_SUBDIR"

	ARG1=${1:-}
	ARG2=${2:-}
	ARG3=${3:-}
	ARG4=${4:-}
	local l_mas_SIGNING_IDENTITY=$ARG1
	local l_mas_PACKAGING_IDENTITY=$ARG2
	local l_mas_TEAM_ID=$ARG3
	local l_mas_COMPANY_NAME=$ARG4

	if [[ -z "${l_mas_COMPANY_NAME}" ]]; then
		echo "No signing parameters were given. Searching..."
		l_mas_SIGNING_IDENTITY=`./$FIND_IDENTITY_SCRIPT mas_app`
		l_mas_PACKAGING_IDENTITY=`./$FIND_IDENTITY_SCRIPT mas_package`
		l_mas_TEAM_ID=`./$FIND_IDENTITY_SCRIPT mas_teamid`
		l_mas_COMPANY_NAME=`./$FIND_IDENTITY_SCRIPT mas_company_name`
	fi

	# Add anchor to correctly check signature
	echo "Adding anchor to correctly check signature ..."
	sudo spctl --add --requirement "anchor apple generic and certificate leaf[subject.CN] = \"3rd Party Mac Developer Application: $l_mas_COMPANY_NAME ($l_mas_TEAM_ID)\"" --label "MAS"

	# Finally sign
	echo "Signing ..."
	"./$MAS_SIGN_SCRIPT" $l_mas_SIGNING_IDENTITY $l_mas_PACKAGING_IDENTITY $l_mas_TEAM_ID "de.iridiumbrowser" $BUNDLE_VERSION "./$IRIDIUM_APP_BUNDLE_NAME" "Iridium" "../"
	cd ..
	rm -rf "$TMP_SUBDIR"

	popd

	echo "You should be able to find Iridium.app and Iridium.pkg in $OUT_DIR/$MAS_SUBDIR"
}


prepare_for_iad() {
	echo "Preparing app as Identified Apple Developer for outside of MAS"
	pushd .

	ARG1=${1:-}
	ARG2=${2:-}
	ARG3=${3:-}
	ARG4=${4:-}

	mkdir -p "$OUT_DIR/$ARG1/$TMP_SUBDIR"

	# Sign Application bundle
	cp "$SIGN_SCRIPTS_PATH/$IAD_SIGN_SCRIPT" "$OUT_DIR/$ARG1/$TMP_SUBDIR/"
	cp "$SIGN_SCRIPTS_PATH/$FIND_IDENTITY_SCRIPT" "$OUT_DIR/$ARG1/$TMP_SUBDIR/"
	cp -af "../$CHROMIUM_SRC_DIR/out/Release/$IRIDIUM_APP_BUNDLE_NAME" "$OUT_DIR/$ARG1/$TMP_SUBDIR/$ARG2"
	cd "$OUT_DIR/$ARG1/$TMP_SUBDIR"

	SIGNING_IDENTITY=`./$FIND_IDENTITY_SCRIPT iad`

	local l_iad_SIGNING_IDENTITY=$ARG4

	if [[ -z "${l_iad_SIGNING_IDENTITY}" ]]; then
		echo "No signing parameters were given. Searching..."
		l_iad_SIGNING_IDENTITY=`./$FIND_IDENTITY_SCRIPT iad`
	fi

	"./$IAD_SIGN_SCRIPT" $l_iad_SIGNING_IDENTITY "de.iridiumbrowser" $BUNDLE_VERSION "./$ARG2" "$ARG3" "../"
	cd ..
	rm -rf $TMP_SUBDIR
	popd

	# Create dmg
	pushd .
	./create_dmg.sh "$OUT_DIR/$ARG1/$ARG2" "$OUT_DIR/$ARG1" "$ARG3"
	popd

	echo "You should be able to find $ARG2 and $ARG3.dmg in $OUT_DIR/$ARG1"
}


prepare_for_nosign() {
	echo "No need to prepare or sign the application, just copy file to out dir"
	pushd .
	mkdir -p "$OUT_DIR/$NOSIGN_SUBDIR"
	cp -af "../$CHROMIUM_SRC_DIR/out/Release/$IRIDIUM_APP_BUNDLE_NAME" "$OUT_DIR/$NOSIGN_SUBDIR/"
	popd

	echo "You should be able to find Iridium.app in $OUT_DIR/$NOSIGN_SUBDIR"
}



# ------------------- Start of the script -------------------

if [ ! -e build.config ]; then
	echo "Config file build.config is not present!"
	exit 1
fi

IFS="="
while read -r name value
do
	if [[ ! $name =~ ^\ *# && -n $name ]]; then
		declare "$name"="$value"
	fi
done < build.config

ARG1=${1:-}

# Check for 'mas' parameter
if [[ -z "${ARG1}" ]]; then
	echo "No arguments were given or more than necessary argument were given."
	print_usage
	exit 1
fi


NO_PATCHING=
NO_PACKAGING=
NO_BUILDING=
IMPORT_IDENTITIES_DIR=
EXTRA_CODECS=

while [[ $# > 0 ]]
do
	key="$1"

	case $key in
		-m|--mode)
			BUILD_MODE="$2"
			shift
			;;
		-i|--identities-dir)
			IMPORT_IDENTITIES_DIR="$2"
			shift
			;;
		-p|--no-patching)
			NO_PATCHING=1
			;;
		-s|--no-packaging)
			NO_PACKAGING=1
			;;
		-b|--no-building)
			NO_BUILDING=1
			;;
		-e|--extra-codecs)
			EXTRA_CODECS=1
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


# install depot_tools
pushd .
cd ..
if ! hash gclient 2>/dev/null && [ ! -d "depot_tools" ]; then
	echo "Installing depot_tools..."
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
export PATH=$PATH:`pwd`/depot_tools
popd


if [[ -z $BUILD_MODE ]]; then
	echo "No mode were given! Aborting..."
	print_usage
	exit 1
fi


# Prepare sources for build
if [[ -z $NO_PATCHING ]]; then
	echo "Run iridium-osx-patch to prepare sources"

	export GYP_DEFINES="proprietary_codecs=1 ffmpeg_branding=Chromium"
	echo "GYP_DEFINES = $GYP_DEFINES"

	echo "Starting at `date`"
	date1=$(date +"%s")

	case $BUILD_MODE in
		"mas")
			if [ ! -z "${TEAM_ID:-}" ]; then
				./iridium-osx-patch.sh -m mas -t $TEAM_ID
			else
				TEAM_ID=`./$SIGN_SCRIPTS_PATH/$FIND_IDENTITY_SCRIPT mas_teamid`
				./iridium-osx-patch.sh -m mas -t $TEAM_ID
			fi
			;;
		"iad")
			if [ ! -z "${TEAM_ID:-}" ]; then
				./iridium-osx-patch.sh -m iad -t $TEAM_ID
			else
				TEAM_ID=`./$SIGN_SCRIPTS_PATH/$FIND_IDENTITY_SCRIPT iad_teamid`
				./iridium-osx-patch.sh -m iad -t $TEAM_ID
			fi
			;;
		"nosign")
			./iridium-osx-patch.sh
			;;
		*)
			echo "Unknown parameter"
			exit 1
			;;
	esac

	date2=$(date +"%s")
	diff=$(($date2-$date1))
	echo "Finished at `date`, $(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
fi


# Building
if [[ -z $NO_BUILDING ]]; then

	echo "Building Iridium"
	echo "Starting at `date`"
	date1=$(date +"%s")

	# Clean up older version of Iridium
		# This is necessary if there was another Iridium.app bundle.
		# In this case post build scripts may fail due to other bundle's structure.
	echo "Cleaning up the older version of $IRIDIUM_APP_BUNDLE_NAME"
	pushd .
	cd "../$CHROMIUM_SRC_DIR/out/Release"
	if [ -e $IRIDIUM_APP_BUNDLE_NAME ]; then
		rm -rf $IRIDIUM_APP_BUNDLE_NAME
	fi
	popd

	# Do actual build
	echo "Start actual building"
	pushd .
	cd "../$CHROMIUM_SRC_DIR"
	ninja -C out/Release

	popd

	date2=$(date +"%s")
	diff=$(($date2-$date1))
	echo "Finished at `date`, $(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
fi


# Import identities from given path
if [[ ! -z $IMPORT_IDENTITIES_DIR ]]; then
	echo "Importing identities to default keychain"
	bash ./$SIGN_SCRIPTS_PATH/$IMPORT_IDENTITIES_SCRIPT $IMPORT_IDENTITIES_DIR
fi


# Do code signing and packaging if appropriate
if [[ -z $NO_PACKAGING ]]; then
	echo "Performing signing/packaging step"

	echo "Starting at `date`"
	date1=$(date +"%s")

	case $BUILD_MODE in
		"mas")
			if [ ! -z "${MAS_SIGNING_IDENTITY:-}" ] && [ ! -z "${MAS_PACKAGE_IDENTITY:-}" ] && [ ! -z "${TEAM_ID:-}" ] && [ ! -z "${SIGNING_IDENTITY_COMPANY_NAME:-}" ]; then
				prepare_for_mas $MAS_SIGNING_IDENTITY $MAS_PACKAGE_IDENTITY $TEAM_ID $SIGNING_IDENTITY_COMPANY_NAME
			else
				prepare_for_mas
			fi
			;;
		"iad")
			if [ ! -z "${IAD_SIGNING_IDENTITY:-}" ]; then
				prepare_for_iad $IAD_SUBDIR $IRIDIUM_APP_BUNDLE_NAME $IRIDIUM_APP_NAME $IAD_SIGNING_IDENTITY
			else
				prepare_for_iad $IAD_SUBDIR $IRIDIUM_APP_BUNDLE_NAME $IRIDIUM_APP_NAME
			fi
			;;
		"nosign")
			prepare_for_nosign
			;;
		*)
			echo "Unknown parameter"
			exit 1
			;;
	esac

	date2=$(date +"%s")
	diff=$(($date2-$date1))
	echo "Finished at `date`, $(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
fi


# Build Iridium with extra codecs
if [[ ! -z $EXTRA_CODECS ]]; then
	echo "Building Irdium-extra"
	
	pushd .
	cd "../$CHROMIUM_SRC_DIR"
	export GYP_DEFINES="proprietary_codecs=1 ffmpeg_branding=Chrome"
	echo "GYP_DEFINES = $GYP_DEFINES"
	python build/gyp_chromium third_party/ffmpeg/ffmpeg.gyp
	gclient runhooks
	ninja -C out/Release
	
	popd

	if [ ! -z "${IAD_SIGNING_IDENTITY:-}" ]; then
		prepare_for_iad $IAD_EXTRA_SUBDIR $IRIDIUM_EXTRA_APP_BUNDLE_NAME $IRIDIUM_EXTRA_APP_NAME $IAD_SIGNING_IDENTITY
	else
		prepare_for_iad $IAD_EXTRA_SUBDIR $IRIDIUM_EXTRA_APP_BUNDLE_NAME $IRIDIUM_EXTRA_APP_NAME
	fi

fi
