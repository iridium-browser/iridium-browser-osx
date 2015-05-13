#!/bin/bash

# Iridium browser OSX import identities script
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


print_usage() {
	echo "import_identities.sh directory [-p|--default-passphrase] [-c|--keychain-password]"
	echo "    Imports all identities from given directory into keychain."
	echo "    Searches only for .p12 files."
	echo "    -p|--default-passphrase - default passphrase which would be applied to all .p12 containers."
	echo "    -c|--keychain-password - password to unlock keychain. It is NOT safeguarded anyhow!!!"
	echo "    -k|--keychain - keychain to import identities. If this argument is not given default keychain assumed."
}


unlock_keychain() {

	PASSWD=${1:-}
	KEYCHAIN=${2:-}

	if [[ -z "${PASSWD}" ]]; then
		# Grab password for unlocking keychain
		stty_orig=`stty -g` # save original terminal setting.
		echo "Please input password to unlock default keychain"
		stty -echo          # turn-off echoing.
		read PASSWD         # read the password
		stty $stty_orig     # restore terminal setting.
	fi

	if [[ -z "${KEYCHAIN}" ]]; then
		security unlock-keychain -p $PASSWD
	else
		security unlock-keychain -p $PASSWD $KEYCHAIN
	fi

	PASSWD=""
}


lock_keychain() {
	KEYCHAIN=${1:-}
	if [[ -z "${KEYCHAIN}" ]]; then
		security lock-keychain
	else
		security lock-keychain $KEYCHAIN
	fi

}


import_identity() {
	# usage: import_identity identity_file passphrase
	# if passphrase is ommited user will be asked to input it.

	ID=${1:-}
	PASSPHR=${2:-}
	KEYCHAIN=${3:-}

	if [[ -z "${ID}" ]]; then
		echo "No identity provided!"
		print_usage
		exit 1
	fi

	if [[ -z "${PASSPHR}" ]]; then
		# Grab passphrase
		stty_orig=`stty -g` # save original terminal setting.
		echo "Please input passphrase for $ID"
		stty -echo          # turn-off echoing.
		read PASSPHR         # read the password
		stty $stty_orig     # restore terminal setting.
	fi

	# import identity
	if [[ -z "${KEYCHAIN}" ]]; then
		security import $ID -P "$PASSPHR" -T /usr/bin/codesign -T /usr/bin/productbuild -T /usr/bin/productsign
	else
		security import $ID -k $KEYCHAIN -P "$PASSPHR" -T /usr/bin/codesign -T /usr/bin/productbuild -T /usr/bin/productsign
	fi

	PASSPHR=""
	echo "Imported identity $ID"
}


# Check if we were given a directory from which to import identities.
DIR=${1:-}

if [[ -z "${DIR}" ]]; then
	echo "No directory with identities provided"
	print_usage
	exit 1
fi

shift


# Grab default passphrase or keychain password

DEFAULT_PASSPHRASE=
KEYCHAIN_PASSWORD=
KEYCHAIN=

while [[ $# > 0 ]]
do
	key="$1"

	case $key in
		-p|--default-passphrase)
			DEFAULT_PASSPHRASE="$2"
			shift
			;;
		-c|--keychain-password)
			KEYCHAIN_PASSWORD="$2"
			shift
			;;
		-k|--keychain)
			KEYCHAIN="$2"
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


# This is a very bad way to check if there is at least one .p12 file.
FOUND_IDENTITY=
FILES=`(find $DIR -maxdepth 1 -name "*.p12")`
for i in $FILES
do
	FOUND_IDENTITY=1
	break
done


# Finally import identites
if [[ ! -z "${FOUND_IDENTITY}" ]]; then

	unlock_keychain $KEYCHAIN_PASSWORD $KEYCHAIN

	for i in $(find $DIR -maxdepth 1 -name "*.p12")
	do
		if [[ -z "${KEYCHAIN}" ]]; then
			import_identity "$i" $DEFAULT_PASSPHRASE
		else
			import_identity "$i" $DEFAULT_PASSPHRASE $KEYCHAIN
		fi
	done

	lock_keychain $KEYCHAIN
else
	echo "No identity files were found in $DIR."
fi
